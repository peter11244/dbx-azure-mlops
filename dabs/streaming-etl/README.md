# Streaming ETL — Databricks Asset Bundle (Delta Live Tables)

A [Databricks Asset Bundle](https://docs.databricks.com/en/dev-tools/bundles/index.html) that deploys a [Delta Live Tables](https://docs.databricks.com/en/delta-live-tables/index.html) pipeline implementing a three-layer streaming medallion architecture (Bronze → Silver → Gold).

## DLT concepts

| Concept | Description |
|---|---|
| **Pipeline** | The DLT unit of deployment. Groups one or more notebooks/Python files that define tables and views. |
| **`@dlt.view`** | Defines a virtual, non-materialised dataset — useful for lightweight sources or intermediate steps that do not need to be stored. |
| **`@dlt.table`** | Defines a materialised Delta table managed by DLT. DLT handles schema evolution, checkpointing, and optimisation automatically. |
| **`@dlt.expect_or_drop`** | A data quality constraint. Rows that violate it are silently dropped before reaching the target table. |
| **Auto Loader (`cloudFiles`)** | Incrementally ingests files from cloud storage (ADLS Gen2, S3, GCS) using checkpointing so each file is processed exactly once. |
| **Triggered mode** | The pipeline runs once and shuts down. Good for scheduled batch-like pipelines that should not incur continuous compute cost. |
| **Continuous mode** | The pipeline keeps a cluster alive and processes data with low latency as it arrives. |

## Prerequisites

| Requirement | Notes |
|---|---|
| [Databricks CLI v0.220+](https://docs.databricks.com/en/dev-tools/cli/install.html) | `brew install databricks` or download from GitHub releases |
| Authenticated session | Run `databricks auth login --host <workspace-url>` once per machine |
| App workspace deployed | Stage 2 Terraform must be applied and the workspace URL must be known |
| Unity Catalog attached | Stage 3 manual step (metastore attachment) and stage 4 Terraform must be complete |

## Variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `workspace_url` | Yes | — | Full HTTPS URL of the app workspace (e.g. `https://adb-123.azuredatabricks.net`) |
| `catalog_name` | No | `main` | Unity Catalog catalog created by stage 4 Terraform |
| `schema_name` | No | `default` | Schema inside the catalog where DLT writes its managed tables |
| `continuous` | No | `false` | Set to `true` for low-latency continuous mode |

Look up the catalog name from the stage 4 Terraform output:

```bash
cd terraform/4-unity-catalog
terraform output catalog_name
```

## Deploy

```bash
cd dabs/streaming-etl

# Validate the bundle (no workspace connection required)
databricks bundle validate --target dev \
  -v workspace_url=https://<workspace>.azuredatabricks.net

# Deploy (creates or updates the DLT pipeline in the workspace)
databricks bundle deploy --target dev \
  -v workspace_url=https://<workspace>.azuredatabricks.net \
  -v catalog_name=main \
  -v schema_name=default
```

## Trigger a pipeline update

After deploying, start a pipeline run (triggered mode):

```bash
databricks bundle run streaming_etl_pipeline --target dev \
  -v workspace_url=https://<workspace>.azuredatabricks.net
```

To switch to **continuous mode** (cluster stays alive):

```bash
databricks bundle deploy --target dev \
  -v workspace_url=https://<workspace>.azuredatabricks.net \
  -v continuous=true

# The pipeline starts automatically once redeployed in continuous mode.
# To stop it, redeploy with continuous=false or destroy the pipeline.
```

## Tear down

```bash
databricks bundle destroy --target dev \
  -v workspace_url=https://<workspace>.azuredatabricks.net
```

## Customising the pipeline

Edit `src/dlt_pipeline.py`:

- **Bronze** — replace the `cloudFiles` path in `raw_events` with your actual ADLS Gen2 path or Unity Catalog volume (e.g. `/Volumes/main/default/landing/`).
- **Silver** — adjust the `expect_or_drop` constraints to match your data quality rules.
- **Gold** — add more aggregations or additional `@dlt.table` definitions for different consumer views.

All three layers are automatically orchestrated by DLT — there is no explicit dependency wiring needed.
