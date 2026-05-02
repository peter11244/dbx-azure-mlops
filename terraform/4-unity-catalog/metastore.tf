data "databricks_current_config" "this" {}

resource "databricks_metastore_assignment" "this" {
  metastore_id = var.metastore_id
  workspace_id = data.databricks_current_config.this.workspace_id
}
