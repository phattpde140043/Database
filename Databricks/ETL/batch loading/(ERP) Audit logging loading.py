# Databricks notebook source
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
    StructField("log_id", StringType(), True),
    StructField("log_time", StringType(), True),
    StructField("user_name", StringType(), True),
    StructField("action_type", StringType(), True),
    StructField("object_type", StringType(), True),
    StructField("object_name", StringType(), True),
    StructField("query", TimestampType(), True)
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

df_enriched = df \
    .withColumn("ingestion_time", current_timestamp()) \
    .withColumn("transaction_type", lit('c')) \
    .withColumn("connector",lit('airflow_batch_load')) \
    .withColumn("hash", sha2(concat_ws("||",col("log_id"),col("log_time"),col("user_name"),col("action_type"),col("object_type"),col("query"),col("object_name")), 256)) \
    .withColumn("source", input_file_name())

# COMMAND ----------

df_deduplicated = (df_enriched
                   .withWatermark("ingestion_time", "1 hour")
                   .dropDuplicates(["log_id", "hash"])
)

# COMMAND ----------

query = (df_deduplicated.writeStream
         .format("delta")
         .outputMode("append")
         .option("checkpointLocation", checkpoint_dir)
         .table(destination_table)
)
query.awaitTermination()