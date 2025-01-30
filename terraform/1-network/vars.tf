variable "cidr_transit" {
  default = "10.10.0.0/16"
  type    = string
}

variable "cidr_dp" {
  default = "10.11.0.0/16"
  type    = string
}

variable "rg_transit" {
  default = "rg-dbx-ml-transit"
  type    = string
}

variable "rg_dp" {
  default = "rg-dbx-ml-dataplane"
  type    = string
}

variable "location" {
  default = "UKSouth"
  type    = string
}

variable "tenant_id" {
  default = "6d2c78dd-1f85-4ccb-9ae3-cd5ea1cca361"
  type = string
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
  prefix   = "adb"
  dbfsname = join("", ["dbfs", "${random_string.naming.result}"])
  tags = {
    Environment = "Demo"
    Owner       = lookup(data.external.me.result, "name")
  }
}