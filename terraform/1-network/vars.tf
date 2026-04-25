variable "cidr_transit" {
  default = "10.10.0.0/16"
  type    = string
}

variable "cidr_dataplane" {
  default = "10.11.0.0/16"
  type    = string
}

variable "cidr_gateway" {
  default = "10.12.0.0/16"
  type    = string
}

variable "cidr_vpn_gateway" {
  default = "10.13.0.0/24"
  type    = string
}



variable "rg_transit" {
  default = "rg-dbx-ml-transit"
  type    = string
}

variable "rg_dataplane" {
  default = "rg-dbx-ml-dataplane"
  type    = string
}

variable "rg_gateway" {
  default = "rg-dbx-ml-gateway"
  type    = string
}


variable "location" {
  default = "WestUS2"
  type    = string
}

variable "subscription_id" {
  type    = string
  default = "972bbe39-991c-4055-80b8-ab36598f89c3"
}

variable "tenant_id" {
  type    = string
  default = "6d2c78dd-1f85-4ccb-9ae3-cd5ea1cca361"
}

data "azurerm_client_config" "current" {
}

data "external" "me" {
  program = ["az", "account", "show", "--query", "user"]
}

resource "random_string" "naming" {
  special = false
  upper   = false
  length  = 6
}

locals {
  prefix   = "dbx-mlops"
  dbfsname = join("", ["dbfs", "${random_string.naming.result}"])
  tags = {
    Environment = "Demo"
    Owner       = lookup(data.external.me.result, "name")
  }
}