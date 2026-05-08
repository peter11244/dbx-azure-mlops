# Batch ETL — Databricks Asset Bundle

A minimal [Databricks Asset Bundle](https://docs.databricks.com/en/dev-tools/bundles/index.html) that deploys a batch ETL job running a PySpark notebook on the app workspace.

## Prerequisites

| Requirement | Notes |
|---|---|
| [Databricks CLI v0.220+](https://docs.databricks.com/en/dev-tools/cli/install.html) | `brew install databricks` or download from GitHub releases |
| Authenticated session | Run `databricks auth login --host <workspace-url>` once per machine |
| App workspace deployed | Stage 2 Terraform must be applied and the workspace URL must be known |
| Stage 3 cluster policy | Stage 3 Terraform must be applied to create the cluster policies |

## Variables

| Variable | Required | Description |
|---|---|---|
| `workspace_url` | Yes | Full HTTPS URL of the app workspace (e.g. `https://adb-123.azuredatabricks.net`) |
| `cluster_policy_id` | No | Policy ID from stage 3 outputs (`single_node_policy_id` or `standard_policy_id`). Leave empty to use no policy. |

Look up the policy ID from the Terraform output:

```bash
cd terraform/3-databricks
terraform output single_node_policy_id
```

## Deploy

```bash
cd dabs/batch-etl

# Validate the bundle
databricks bundle validate --target dev \
  -v workspace_url=https://<workspace>.azuredatabricks.net

# Deploy (uploads the notebook and creates the job)
databricks bundle deploy --target dev \
  -v workspace_url=https://<workspace>.azuredatabricks.net \
  -v cluster_policy_id=<policy-id>

# Run the job immediately
databricks bundle run batch_etl_job --target dev \
  -v workspace_url=https://<workspace>.azuredatabricks.net
```

## Tear down

```bash
databricks bundle destroy --target dev \
  -v workspace_url=https://<workspace>.azuredatabricks.net
```

## Customising the notebook

Edit `src/etl_notebook.py`. The file uses standard Python — replace the placeholder
`createDataFrame` call with real data sources (ADLS Gen2 mounts, Unity Catalog volumes,
or external tables) and write the result to a Delta table with `saveAsTable`.
