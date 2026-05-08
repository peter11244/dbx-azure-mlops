# Databricks notebook source
# COMMAND ----------

# Placeholder batch ETL notebook
# Replace the sections below with your actual data sources and transformations.

from pyspark.sql import SparkSession
from pyspark.sql import functions as F

spark = SparkSession.builder.getOrCreate()

# COMMAND ----------

# --- Extract ---
# Read raw data from a source (e.g. ADLS Gen2 mount, Unity Catalog volume, or Delta table).
# Example:
#   df_raw = spark.read.format("parquet").load("/mnt/raw/events/")

df_raw = spark.createDataFrame(
    [("alice", 1), ("bob", 2), ("alice", 3)],
    schema=["name", "value"],
)

# COMMAND ----------

# --- Transform ---
df_agg = df_raw.groupBy("name").agg(F.sum("value").alias("total_value"))

# COMMAND ----------

# --- Load ---
# Write the result to a Delta table or Unity Catalog.
# Example:
#   df_agg.write.format("delta").mode("overwrite").saveAsTable("main.default.batch_etl_output")

display(df_agg)
