resource "databricks_storage_credential" "main" {
  name = "${var.catalog_name}-credential"
  azure_managed_identity {
    access_connector_id = var.managed_identity_id
  }
  depends_on = [databricks_metastore_assignment.this]
}

resource "databricks_catalog" "main" {
  name    = var.catalog_name
  comment = "Root catalog — storage access via ${databricks_storage_credential.main.name}"

  depends_on = [databricks_storage_credential.main]
}

resource "databricks_schema" "default" {
  catalog_name = databricks_catalog.main.name
  name         = "default"
}
