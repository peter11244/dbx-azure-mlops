# Databricks notebook source
# COMMAND ----------

# Delta Live Tables streaming pipeline
# Implements a three-layer medallion pattern: Bronze → Silver → Gold.
# DLT manages checkpointing, schema evolution, and data quality automatically.

import dlt
from pyspark.sql import functions as F
from pyspark.sql.types import StructType, StructField, StringType, LongType, DoubleType

# COMMAND ----------

# --- Bronze layer: ingest raw events via Auto Loader ---
# @dlt.view keeps the result in memory; it is not materialised as a Delta table.
# Use it for lightweight transformations or sources you want to reference by name.

@dlt.view(
    comment="Raw events streamed from ADLS Gen2 via Auto Loader (cloudFiles).",
)
def raw_events():
    # Replace the path below with your actual ADLS Gen2 or Unity Catalog volume path.
    # Auto Loader (cloudFiles) handles schema inference and file-tracking automatically.
    return (
        spark.readStream
            .format("cloudFiles")
            .option("cloudFiles.format", "json")
            .option("cloudFiles.schemaLocation", "/tmp/streaming_etl_schema")
            .load("/databricks-datasets/structured-streaming/events/")
    )

# COMMAND ----------

# --- Silver layer: cleaned and deduplicated events ---
# @dlt.table materialises the result as a managed Delta table in the target schema.
# `expect` / `expect_or_drop` clauses enforce data quality as declarative constraints.

@dlt.table(
    comment="Deduplicated events with parsed timestamp. Rows failing quality checks are dropped.",
    table_properties={"quality": "silver", "delta.autoOptimize.optimizeWrite": "true"},
)
@dlt.expect_or_drop("valid_action", "action IS NOT NULL")
@dlt.expect_or_drop("valid_time",   "timestamp IS NOT NULL")
def cleaned_events():
    return (
        dlt.read_stream("raw_events")
            .dropDuplicates(["id"])
            .withColumn("event_ts", F.to_timestamp(F.col("timestamp").cast("double")))
            .select("id", "action", "event_ts")
    )

# COMMAND ----------

# --- Gold layer: aggregated metrics ---
# Gold tables are typically read by BI tools or downstream jobs.
# Using dlt.read() (non-streaming) to consume the Silver table as a batch.

@dlt.table(
    comment="Hourly event counts per action type, derived from the Silver layer.",
    table_properties={"quality": "gold"},
)
def hourly_event_counts():
    return (
        dlt.read("cleaned_events")
            .groupBy(
                F.window("event_ts", "1 hour").alias("hour_window"),
                "action",
            )
            .agg(F.count("*").alias("event_count"))
            .select(
                F.col("hour_window.start").alias("window_start"),
                F.col("hour_window.end").alias("window_end"),
                "action",
                "event_count",
            )
    )
