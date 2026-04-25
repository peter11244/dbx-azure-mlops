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

variable "location" {
  default = "WestUS2"
  type    = string
}

variable "tfstate_account_replication_type" {
  default = "LRS"
  type    = string
}

locals {
  rg_tfstate   = "rg-${var.naming_prefix}-tfstate"
  rg_gateway   = "rg-${var.naming_prefix}-gateway"
  rg_transit   = "rg-${var.naming_prefix}-transit"
  rg_dataplane = "rg-${var.naming_prefix}-dataplane"
}
