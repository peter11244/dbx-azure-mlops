terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.17.0"
    }

    databricks = {
      source  = "databricks/databricks"
      version = "1.64.1"
    }
  }

  backend "azurerm" {}
}

provider "databricks" {
  host = var.workspace_url
}