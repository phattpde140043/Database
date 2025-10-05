# Databricks notebook source
# MAGIC %sql
# MAGIC USE CATALOG  bronze_layer;

# COMMAND ----------

from pyspark.sql import SparkSession
from pyspark.sql.functions import (
    col, from_json, from_unixtime, concat_ws, sha2, hex, coalesce, lit,current_timestamp,input_file_name
)
from pyspark.sql.types import StructType, StructField, StringType, BinaryType, TimestampType

# COMMAND ----------

checkpoint_dir = "/path/to/checkpoint"
schema_dir = "/path/to/schema/account"
source_path = "http://localhost:8083/account/"   
destination_table = "bronze_pos.customers"

# COMMAND ----------

spark = (SparkSession.builder
         .appName("AutoLoaderCustomers")
         .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension")
         .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog")
         .getOrCreate())

# COMMAND ----------

# Định nghĩa schema
schema = StructType([
    StructField("payment_type_id", StringType(), True),
    StructField("name", StringType(), True),
    StructField("updated_at", TimestampType(), True)
])

# COMMAND ----------

df = (spark.readStream
          .format("cloudFiles")\
          .option("cloudFiles.format", "parquet")\
          .option("cloudFiles.schemaLocation", schema_dir)\
          .schema(schema)\
          .load(source_path)
     )

# COMMAND ----------

# Thêm cột phụ
df_enriched = df \
    .withColumn("ingestion_time", current_timestamp()) \
    .withColumn("transaction_type", lit('c')) \
    .withColumn("connector",lit('airflow_batch_load')) \
    .withColumn("hash", sha2(concat_ws("||",col("payment_type_id"),col("name"),col("updated_at")), 256)) \
    .withColumn("source", input_file_name())

# COMMAND ----------

# Loại bỏ trùng lặp dựa trên customer_id và hash, với watermark 1 giờ
df_deduplicated = df_customers \
    .withWatermark("ingestion_time", "1 hour") \
    .dropDuplicates("payment_type_id", "hash")

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