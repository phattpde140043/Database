# Databricks notebook source
# MAGIC %sql
# MAGIC USE CATALOG  bronze_layer;

# COMMAND ----------

# Đọc dữ liệu streaming từ Kafka
kafka_bootstrap = "0.tcp.ap.ngrok.io:12874"
topic = "erpdbserver.public.employees"
checkpoint_dir = "/path/to/checkpoint"
destination_table ="bronze_erp.employees"


# COMMAND ----------

from pyspark.sql import SparkSession
from pyspark.sql.functions import col, from_json, from_unixtime, concat_ws, sha2, hex, coalesce, lit,udf, unbase64
from pyspark.sql.types import StructType, StructField, StringType, BinaryType, TimestampType,IntegerType, DecimalType,LongType
import base64, decimal

# COMMAND ----------

def decode_decimal(b64_str):
    if b64_str is None:
        return None
    b = base64.b64decode(b64_str)
    unscaled = int.from_bytes(b, byteorder="big", signed=True)
    return decimal.Decimal(unscaled).scaleb(-2)   # scale -2 vì DECIMAL(12,2)

# COMMAND ----------

decode_decimal_udf = udf(decode_decimal, DecimalType(12,2))

# COMMAND ----------

# Khởi tạo SparkSession
spark = SparkSession.builder \
    .appName("KafkaBatchToDelta") \
    .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension") \
    .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog") \
    .getOrCreate()

# COMMAND ----------

# Định nghĩa schema tối ưu cho payload
schema = StructType([
    StructField("payload", StructType([
        StructField("op", StringType(), False),
        StructField("after", StructType([
            StructField("employee_id", StringType(), False),
            StructField("name", StringType(), False),
            StructField("email", BinaryType(), False),
            StructField("department_id", LongType(), False),
            StructField("hire_date", StringType(), False),
            StructField("salary", StringType(), False),
            StructField("deleted_at", StringType(), False),
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

df = (
    spark.read
    .format("kafka")
    .option("kafka.bootstrap.servers", kafka_bootstrap)
    .option("subscribe", topic)
    .option("startingOffsets", "earliest")  # Đọc từ đầu
    .option("endingOffsets", "latest")  # Đọc đến offset mới nhất
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
    col("data.payload.after.employee_id").alias("employee_id"),
    col("data.payload.after.name").alias("name"),
    col("data.payload.after.email").alias("email"),
    col("data.payload.after.department_id").alias("department_id"),
    col("data.payload.after.hire_date").cast(TimestampType()).alias("hire_date"),
    decode_decimal_udf(col("data.payload.after.salary")).alias("salary"),
    col("data.payload.after.deleted_at").cast(TimestampType()).alias("deleted_at"),
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
            coalesce(col("data.payload.after.employee_id"), lit("")),
            coalesce(col("data.payload.after.name"), lit("")),
            coalesce(hex(col("data.payload.after.email")), lit("")),
            coalesce(col("data.payload.after.department_id").cast("string"), lit("")),
            coalesce(col("data.payload.after.hire_date").cast("string"), lit("")),
            coalesce(col("data.payload.after.salary").cast("string"), lit("")),
            coalesce(col("data.payload.after.deleted_at").cast("string"), lit("")),
            coalesce(col("data.payload.after.updated_at").cast("string"), lit(""))
        ),
        256
    ).alias("hash")
)

# COMMAND ----------

# Loại bỏ trùng lặp dựa trên customer_id và hash, với watermark 1 giờ
df_deduplicated = df_customers \
    .withWatermark("ingestion_time", "1 hour") \
    .dropDuplicates(["employee_id", "hash"])

# COMMAND ----------


# Ghi dữ liệu vào bảng Delta
df_customers.write.format("delta").mode("append") .saveAsTable(destination_table)

# Dừng SparkSession
spark.stop()