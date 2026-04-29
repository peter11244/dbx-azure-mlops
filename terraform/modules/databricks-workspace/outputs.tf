output "workspace_id" {
  description = "Resource ID of the Databricks workspace"
  value       = azurerm_databricks_workspace.this.id
}

output "workspace_url" {
  description = "Workspace URL of the Databricks workspace"
  value       = azurerm_databricks_workspace.this.workspace_url
}
