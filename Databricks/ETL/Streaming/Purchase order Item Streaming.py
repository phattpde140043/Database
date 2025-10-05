# Databricks notebook source
# MAGIC %sql
# MAGIC USE CATALOG  bronze_layer;

# COMMAND ----------

from pyspark.sql import SparkSession
from pyspark.sql.functions import col, from_json, from_unixtime, concat_ws, sha2, hex, coalesce, lit
from pyspark.sql.types import StructType, StructField, StringType, BinaryType, TimestampType,LongType, IntegerType, DecimalType
import base64, decimal

# COMMAND ----------

# Đọc dữ liệu streaming từ Kafka
kafka_bootstrap = "0.tcp.ap.ngrok.io:13686"
topic = "erpdbserver.public.purchase_order_items"
checkpoint_dir = "/path/to/checkpoint"
destination_table ="bronze_pos.purchase_order_items"

# COMMAND ----------

def decode_decimal(b64_str):
    if b64_str is None:
        return None
    b = base64.b64decode(b64_str)
    unscaled = int.from_bytes(b, byteorder="big", signed=True)
    return decimal.Decimal(unscaled).scaleb(-2)  

# COMMAND ----------

decode_decimal_udf = udf(decode_decimal, DecimalType(10,2))

# COMMAND ----------

# Định nghĩa schema tối ưu cho payload
schema = StructType([
    StructField("payload", StructType([
        StructField("op", StringType(), False),
        StructField("after", StructType([
            StructField("po_item_id", LongType(), False),
            StructField("po_id", LongType(), False),
            StructField("product_id", StringType(), False),
            StructField("quantity", IntegerType(), False),
            StructField("unit_price", StringType(), False),
            StructField("order_date", StringType(), False),
            StructField("updated_at", StringType(), False)
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
    col("data.payload.after.po_item_id").alias("po_item_id"),
    col("data.payload.after.po_id").alias("po_id"),
    col("data.payload.after.product_id").alias("product_id"),
    col("data.payload.after.quantity").alias("quantity"),
    decode_decimal_udf(col("data.payload.after.unit_price")).alias("unit_price"),
    col("data.payload.after.order_date").cast(TimestampType()).alias("created_at"),
    col("data.payload.after.updated_at").cast(TimestampType()).alias("updated_at"),
    # Metadata
    from_unixtime(col("data.payload.ts_ms") / 1000).cast(TimestampType()).alias("ingestion_time"),
    col("data.payload.op").alias("transaction_type"),
    concat_ws("_", col("data.payload.source.connector"), col("data.payload.source.name")).alias("connector"),
    concat_ws(".", col("data.payload.source.db"), col("data.payload.source.schema"), col("data.payload.source.table")).alias("source"),
    # Hash của dữ liệu chính (SHA-256)
    sha2(
        concat_ws(
            "|",
            coalesce(col("data.payload.after.po_item_id").cast("string"), lit("")),
            coalesce(col("data.payload.after.po_id").cast("string"), lit("")),
            coalesce(col("data.payload.after.product_id"), lit("")),
            coalesce(col("data.payload.after.quantity").cast("string"), lit("")),
            coalesce(col("data.payload.after.unit_price").cast("string"), lit("")),
            coalesce(col("data.payload.after.order_date").cast("string"), lit("")),
            coalesce(col("data.payload.after.updated_at").cast("string"), lit(""))
        ),
        256
    ).alias("hash")
)

# COMMAND ----------

# Loại bỏ trùng lặp dựa trên customer_id và hash, với watermark 1 giờ
df_deduplicated = df_customers \
    .withWatermark("ingestion_time", "1 hour") \
    .dropDuplicates(["po_item_id", "hash"])

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