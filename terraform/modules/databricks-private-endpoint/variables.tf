variable "name" {
  type        = string
  description = "Name of the private endpoint resource"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to deploy the private endpoint into"
}

variable "location" {
  type        = string
  description = "Azure region for the private endpoint"
}

variable "subnet_id" {
  type        = string
  description = "Resource ID of the subnet to place the private endpoint in"
}

variable "workspace_id" {
  type        = string
  description = "Resource ID of the Databricks workspace to connect"
}

variable "subresource_name" {
  type        = string
  description = "Databricks subresource to expose (databricks_ui_api or browser_authentication)"
}

variable "private_dns_zone_id" {
  type        = string
  description = "Resource ID of the private DNS zone for automatic DNS registration"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to the private endpoint resource"
}
