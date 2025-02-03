terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.17.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-dbx-ml-tfstate"             # Can be passed via `-backend-config=`"resource_group_name=<resource group name>"` in the `init` command.
    storage_account_name = "tfstateb563727617b12739"       # Can be passed via `-backend-config=`"storage_account_name=<storage account name>"` in the `init` command.
    container_name       = "tfstate"                       # Can be passed via `-backend-config=`"container_name=<container name>"` in the `init` command.
    key                  = "network.terraform.tfstate"        # Can be passed via `-backend-config=`"key=<blob key name>"` in the `init` command.
    use_azuread_auth     = true                            # Can also be set via `ARM_USE_AZUREAD` environment variable.

  }
}

provider "azurerm" {
  subscription_id = "972bbe39-991c-4055-80b8-ab36598f89c3" # VSES – MPN - Peter Sach
  features {}
}

