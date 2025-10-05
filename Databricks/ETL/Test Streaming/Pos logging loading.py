# Databricks notebook source
# MAGIC %sql
# MAGIC USE CATALOG  bronze_layer;

# COMMAND ----------

from pyspark.sql import SparkSession
from pyspark.sql.functions import col, from_json, from_unixtime, concat_ws, sha2, hex, coalesce, lit,timestamp_micros
from pyspark.sql.types import StructType, StructField, StringType, BinaryType, TimestampType,LongType, IntegerType, DecimalType
import base64, decimal

# COMMAND ----------

# Đọc dữ liệu streaming từ Kafka
kafka_bootstrap = "0.tcp.ap.ngrok.io:14983"
topic = "posdbserver.public.audit_log"
checkpoint_dir = "/path/to/checkpoint"
destination_table ="bronze_pos.audit_log"

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
            StructField("log_id", LongType(), False),
            StructField("log_time", StringType(), False),
            StructField("user_name", StringType(), False),
            StructField("action_type", StringType(), False),
            StructField("object_type", StringType(), False),
            StructField("object_name", StringType(), False),
            StructField("query", StringType(), False)
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
    spark.read
    .format("kafka")
    .option("kafka.bootstrap.servers", kafka_bootstrap)
    .option("subscribe", topic)
    .option("startingOffsets", "earliest")
    .option("endingOffsets", "latest")
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
    col("data.payload.after.log_id").alias("log_id"),
    timestamp_micros(col("data.payload.after.log_time").cast("bigint")).alias("log_time"),
    col("data.payload.after.user_name").alias("user_name"),
    col("data.payload.after.action_type").alias("action_type"),
    col("data.payload.after.object_type").alias("object_type"),
    col("data.payload.after.object_name").alias("object_name"),
    col("data.payload.after.query").alias("query"),
    # Metadata
    from_unixtime(col("data.payload.ts_ms") / 1000).cast(TimestampType()).alias("ingestion_time"),
    col("data.payload.op").alias("transaction_type"),
    concat_ws("_", col("data.payload.source.connector"), col("data.payload.source.name")).alias("connector"),
    concat_ws(".", col("data.payload.source.db"), col("data.payload.source.schema"), col("data.payload.source.table")).alias("source"),
    # Hash của dữ liệu chính (SHA-256)
    sha2(
        concat_ws(
            "|",
            coalesce(col("data.payload.after.log_id").cast("string"), lit("")),
            coalesce(col("data.payload.after.log_time"), lit("")),
            coalesce(col("data.payload.after.user_name"), lit("")),
            coalesce(col("data.payload.after.action_type"), lit("")),
            coalesce(col("data.payload.after.object_type"), lit("")),
            coalesce(col("data.payload.after.object_name"), lit("")),
            coalesce(col("data.payload.after.query"), lit("")),
        ),
        256
    ).alias("hash")
)

# COMMAND ----------

# Loại bỏ trùng lặp dựa trên customer_id và hash, với watermark 1 giờ
df_deduplicated = df_customers \
    .withWatermark("ingestion_time", "1 hour") \
    .dropDuplicates(["log_id", "hash"])

# COMMAND ----------

# Ghi dữ liệu vào bảng Delta
df_deduplicated.write.format("delta").mode("append") .saveAsTable(destination_table)

# Dừng SparkSession
spark.stop()