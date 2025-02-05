variable "phase_1_state_backend_resource_group_name" {
  default = "rg-dbx-ml-tfstate"
  type    = string
}


variable "phase_1_state_backend_storage_account_name" {
  default = "tfstateb563727617b12739"
  type    = string
}


variable "phase_1_state_backend_container_name" {
  default = "tfstate"
  type    = string
}


variable "phase_1_state_backend_key_name" {
  default = "network.terraform.tfstate"
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

variable "location" {
  default = "WestUS2"
  type    = string
}

variable "tenant_id" {
  default = "6d2c78dd-1f85-4ccb-9ae3-cd5ea1cca361"
  type = string
}

variable "subscription_id" {
  default = "972bbe39-991c-4055-80b8-ab36598f89c3"
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