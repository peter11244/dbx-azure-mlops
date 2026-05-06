resource "databricks_secret_scope" "key_vault" {
  name = "${var.naming_prefix}-kv-scope"

  keyvault_metadata {
    resource_id = var.key_vault_id
    dns_name    = var.key_vault_uri
  }
}
