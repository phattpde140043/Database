# Databricks notebook source
# MAGIC %sql
# MAGIC USE CATALOG  bronze_layer;

# COMMAND ----------

from pyspark.sql import SparkSession
from pyspark.sql.functions import col, from_json, from_unixtime, concat_ws, sha2, hex, coalesce, lit
from pyspark.sql.types import StructType, StructField, StringType, BinaryType, TimestampType,LongType, IntegerType, DecimalType

# COMMAND ----------

# Đọc dữ liệu streaming từ Kafka
kafka_bootstrap = "0.tcp.ap.ngrok.io:13686"
topic = "logdbserver.public.inventory"
checkpoint_dir = "/path/to/checkpoint"
destination_table ="bronze_pos.inventory"

# COMMAND ----------

# Định nghĩa schema tối ưu cho payload
schema = StructType([
    StructField("payload", StructType([
        StructField("op", StringType(), False),
        StructField("after", StructType([
            StructField("inventory_id", LongType(), False),
            StructField("warehouse_id", LongType(), False),
            StructField("product_id", StringType(), False),
            StructField("sku_id", LongType(), False),
            StructField("stock_quantity", IntegerType(), False),
            StructField("last_updated", StringType(), False)
        ]), True),
        StructField("source", StructType([
            StructField("connector", StringType(), False),
            StructField("name", StringType(), False),
            StructField("db", StringType(), False),
            StructField("schema", StringType(), False),
            StructField("table", StringType(), False)
        ]), False),
        StructField("ts_ms", StringType(), True)
    ]), False)
])

# COMMAND ----------

# Khởi tạo SparkSession
spark = SparkSession.builder \
    .appName("KafkaBatchToDelta") \
    .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension") \
    .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog") \
    .getOrCreate()

# COMMAND ----------

df = (
    spark.readStream
    .format("kafka")
    .option("kafka.bootstrap.servers", kafka_bootstrap)  
    .option("subscribe", topic)                         
    .option("startingOffsets", "earliest")               
    .load()
)


# COMMAND ----------

# Chuyển đổi value từ Kafka thành string và parse JSON
df_str = df.selectExpr("CAST(value AS STRING) as value")
df_json = df_str.select(from_json(col("value"), schema).alias("data"))

# COMMAND ----------

# Lọc các bản ghi với op là "r" (snapshot), "c" (create), hoặc "u" (update)
df_customers = df_json.filter(col("data.payload.op").isin("r", "c", "u")).select(
    # Dữ liệu chính từ after
    col("data.payload.after.inventory_id").alias("inventory_id"),
    col("data.payload.after.warehouse_id").alias("warehouse_id"),
    col("data.payload.after.product_id").alias("product_id"),
    col("data.payload.after.sku_id").alias("sku_id"),
    col("data.payload.after.stock_quantity").alias("stock_quantity"),
    col("data.payload.after.last_updated").cast(TimestampType()).alias("last_updated"),
    # Metadata
    from_unixtime(col("data.payload.ts_ms") / 1000).cast(TimestampType()).alias("ingestion_time"),
    col("data.payload.op").alias("transaction_type"),
    concat_ws("_", col("data.payload.source.connector"), col("data.payload.source.name")).alias("connector"),
    concat_ws(".", col("data.payload.source.db"), col("data.payload.source.schema"), col("data.payload.source.table")).alias("source"),
    # Hash của dữ liệu chính (SHA-256)
    sha2(
        concat_ws(
            "|",
            coalesce(col("data.payload.after.inventory_id"), lit("")),
            coalesce(col("data.payload.after.warehouse_id"), lit("")),
            coalesce(col("data.payload.after.product_id"), lit("")),
            coalesce(col("data.payload.after.sku_id"), lit("")),
            coalesce(col("data.payload.after.stock_quantity"), lit("")),
            coalesce(col("data.payload.after.last_updated").cast("string"), lit(""))
        ),
        256
    ).alias("hash")
)

# COMMAND ----------

# Loại bỏ trùng lặp dựa trên customer_id và hash, với watermark 1 giờ
df_deduplicated = df_customers \
    .withWatermark("ingestion_time", "1 hour") \
    .dropDuplicates(["inventory_id", "hash"])

# COMMAND ----------

# Ghi dữ liệu vào bảng Delta
query = (
    df_deduplicated.writeStream
    .format("delta")
    .outputMode("append")
    .option("checkpointLocation", checkpoint_dir)  # Thư mục checkpoint
    .table(destination_table)
)
# Bắt đầu streaming
query.awaitTermination()