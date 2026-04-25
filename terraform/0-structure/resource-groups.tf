#######################
##  RESOURCE GROUPS  ##
#######################

# Create Resource Groups for each part of the architecture.


resource "azurerm_resource_group" "tfstate" {
  name     = local.rg_tfstate
  location = var.location
}

resource "azurerm_resource_group" "transit" {
  name     = local.rg_transit
  location = var.location
}

resource "azurerm_resource_group" "dataplane" {
  name     = local.rg_dataplane
  location = var.location
}

resource "azurerm_resource_group" "gateway" {
  name     = local.rg_gateway
  location = var.location
}
