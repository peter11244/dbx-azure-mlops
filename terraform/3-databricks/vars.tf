variable "naming_prefix" {
  type    = string
  default = "dbx-ml"
}

variable "subscription_id" {
  type    = string
  default = "972bbe39-991c-4055-80b8-ab36598f89c3"
}

variable "tenant_id" {
  type    = string
  default = "6d2c78dd-1f85-4ccb-9ae3-cd5ea1cca361"
}

variable "workspace_url" {
  default = "https://adb-696792267492982.2.azuredatabricks.net"
  type    = string
}

variable "environment" {
  type    = string
  default = "Demo"
}

variable "key_vault_id" {
  type        = string
  description = "Resource ID of the Azure Key Vault to back the secret scope"
}

variable "key_vault_uri" {
  type        = string
  description = "Vault URI of the Azure Key Vault"
}