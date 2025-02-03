#######################
##  RESOURCE GROUPS  ## 
#######################

# Create Resource Groups for each part of the architecture.


resource "azurerm_resource_group" "tfstate" {
  name     = var.rg_tfstate
  location = var.location
}

resource "azurerm_resource_group" "transit" {
  name     = var.rg_transit
  location = var.location
}

resource "azurerm_resource_group" "dataplane" {
  name     = var.rg_dataplane
  location = var.location
}

resource "azurerm_resource_group" "gateway" {
  name     = var.rg_gateway
  location = var.location
}
