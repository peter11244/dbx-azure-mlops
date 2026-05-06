variable "metastore_id" {
  type        = string
  description = "ID of the existing Unity Catalog metastore (from Account Console)"
}

variable "catalog_name" {
  type        = string
  default     = "main"
  description = "Name of the Unity Catalog catalog to create"
}

variable "managed_identity_id" {
  type        = string
  description = "Resource ID of the Azure Access Connector (managed identity) for the storage credential"
}
