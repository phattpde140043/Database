# Databricks notebook source
from pyspark.sql import SparkSession
from pyspark.sql.functions import row_number, desc,col, current_date, date_sub,current_timestamp,sha2, hex, concat_ws, lit,coalesce
from delta.tables import DeltaTable
from pyspark.sql.window import Window
import json

source_table = "bronze_logistic.audit_log"
target_table = "silver_database.audit_log"
primary_key = "log_id"

# COMMAND ----------

spark = (SparkSession.builder
         .appName("BronzeToSilverPipeline")
         .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension")
         .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog")
         .getOrCreate())

# COMMAND ----------

# Chọn catalog bronze_layer
spark.sql("USE CATALOG bronze_layer")
# lấy bảng, lọc dữ liệu theo ingestion time và loại dữ liệu trùng
bronze_df = spark.read.table(source_table)\
        .filter(col("ingestion_time") >= date_sub(current_date(), 14))\
        .dropDuplicates(["hash"])
# group dữ liệu bằng customer_id và orders theo updated_at
window_spec = Window.partitionBy(primary_key).orderBy(desc("ingestion_time"))
# chỉ giữ lại dữ liệu mới nhất
bronze_dedup_df = (bronze_df
    .withColumn("rank", row_number().over(window_spec))
    .filter(col("rank") == 1)
    .drop("rank")
)

# COMMAND ----------

display(bronze_dedup_df)

# COMMAND ----------

# Chọn catalog bronze_layer
spark.sql("USE CATALOG silver_layer")
# Target: Silver table (DeltaTable)
silver_table = DeltaTable.forName(spark, target_table)

# COMMAND ----------

# Merge DeltaTable (target) với DataFrame (source)
merge_builder = (silver_table.alias("target").merge(bronze_dedup_df.alias("source"),"target."+primary_key+" = source."+primary_key+" AND target.database_source = 'Logistic'")\
 .whenMatchedUpdate(
    condition="target.hash != source.hash",
    set={
        "log_id":col("source.log_id"),
        "log_time":col("source.log_time"),
        "user_name":col("source.user_name"),
        "action_type":col("source.action_type"),
        "object_type":col("source.object_type"),
        "object_name":col("source.object_name"),
        "query":col("source.query"),
        "ingestion_time":current_timestamp(),
        "hash":col("source.hash")
    }
 )\
 .whenNotMatchedInsert(
     values={
        "log_id":col("source.log_id"),
        "log_time":col("source.log_time"),
        "database_source": lit("Logistic"),
        "user_name":col("source.user_name"),
        "action_type":col("source.action_type"),
        "object_type":col("source.object_type"),
        "object_name":col("source.object_name"),
        "query":col("source.query"),
        "ingestion_time":current_timestamp(),
        "hash":sha2(
        concat_ws(
            "|",
            coalesce(col("source.log_id").cast("string"), lit("")),
            coalesce(col("source.log_time").cast("string"), lit("")),
            coalesce(col("source.user_name"), lit("")),
            coalesce(col("source.action_type"), lit("")),
            coalesce(col("source.object_type"), lit("")),
            coalesce(col("source.object_name"), lit("")),
            coalesce(col("source.query"), lit("")),
        ),
        256
    )
    }
 ).execute())

# Lấy log mới nhất
metrics = silver_table.history(1).select("operationMetrics").collect()[0][0]
print("✅ Merge thành công.")
print(f"Số dòng inserted: {metrics.get('numTargetRowsInserted', 0)}")
print(f"Số dòng updated:  {metrics.get('numTargetRowsUpdated', 0)}")
print(f"Số dòng deleted:  {metrics.get('numTargetRowsDeleted', 0)}")

# COMMAND ----------

display(silver_table.toDF())