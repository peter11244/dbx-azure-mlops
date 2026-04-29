variable "workspace_name" {
  type        = string
  description = "Name of the Databricks workspace"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to deploy the workspace into"
}

variable "location" {
  type        = string
  description = "Azure region for the workspace"
}

variable "vnet_id" {
  type        = string
  description = "Resource ID of the VNet for VNet injection"
}

variable "public_subnet_name" {
  type        = string
  description = "Name of the public (container) subnet for VNet injection"
}

variable "private_subnet_name" {
  type        = string
  description = "Name of the private (host) subnet for VNet injection"
}

variable "public_subnet_nsg_id" {
  type        = string
  description = "Resource ID of the NSG association on the public subnet"
}

variable "private_subnet_nsg_id" {
  type        = string
  description = "Resource ID of the NSG association on the private subnet"
}

variable "storage_account_name" {
  type        = string
  description = "Name of the DBFS root storage account (must be globally unique, 3-24 lowercase alphanumeric)"
}

variable "sku" {
  type        = string
  default     = "premium"
  description = "Databricks workspace SKU"
}

variable "no_public_ip" {
  type        = bool
  default     = true
  description = "Disable public IPs on cluster nodes"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to the workspace resource"
}
