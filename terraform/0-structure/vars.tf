variable "rg_tfstate" {
  default = "rg-dbx-ml-tfstate"
  type    = string
}

variable "rg_gateway" {
  default = "rg-dbx-ml-gateway"
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
  default = "UKSouth"
  type    = string
}

variable "tfstate_account_replication_type" {
  default = "LRS"
  type    = string
}