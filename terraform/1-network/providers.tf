terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.1.0"
    }
  }
}

provider "azurerm" {

  subscription_id = "972bbe39-991c-4055-80b8-ab36598f89c3" # VSES – MPN - Peter Sach

  features {}
}