#######################
##  DATA PLANE VNET  ##
#######################

# The data plane VNet is the network that contains the Databricks workspace and the private endpoints.
# It contains the workspace, and the clusters for use within the workspace. Users do not have direct access to this network.


resource "azurerm_virtual_network" "app_vnet" {
  name                = "${local.prefix}-app-vnet"
  location            = var.location
  resource_group_name = var.rg_dataplane
  address_space       = [var.cidr_dataplane]
  tags                = local.tags
}

resource "azurerm_network_security_group" "app_sg" {
  name                = "${local.prefix}-app-nsg"
  location            = var.location
  resource_group_name = var.rg_dataplane
  tags                = local.tags
}

resource "azurerm_network_security_rule" "app_aad" {
  name                        = "AllowAAD-app"
  priority                    = 200
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "AzureActiveDirectory"
  resource_group_name         = var.rg_dataplane
  network_security_group_name = azurerm_network_security_group.app_sg.name
}

resource "azurerm_network_security_rule" "app_azfrontdoor" {
  name                        = "AllowAzureFrontDoor-app"
  priority                    = 201
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "AzureFrontDoor.Frontend"
  resource_group_name         = var.rg_dataplane
  network_security_group_name = azurerm_network_security_group.app_sg.name
}


###
## PRIVATE DNS
### 

resource "azurerm_private_dns_zone" "dnsdpcp" {
  name                = "privatelink.azuredatabricks.net"
  resource_group_name = var.rg_dataplane
}

resource "azurerm_private_dns_zone_virtual_network_link" "uiapidnszonevnetlink" {
  name                  = "dpcpvnetconnection"
  resource_group_name   = var.rg_dataplane
  private_dns_zone_name = azurerm_private_dns_zone.dnsdpcp.name
  virtual_network_id    = azurerm_virtual_network.app_vnet.id
}

###
## DATABRICKS WORKSPACE
###

resource "azurerm_subnet" "app_public" {
  name                 = "${local.prefix}-app-public"
  resource_group_name  = var.rg_dataplane
  virtual_network_name = azurerm_virtual_network.app_vnet.name
  address_prefixes     = [cidrsubnet(var.cidr_dataplane, 6, 0)]

  delegation {
    name = "databricks"
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
      "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "app_public" {
  subnet_id                 = azurerm_subnet.app_public.id
  network_security_group_id = azurerm_network_security_group.app_sg.id
}

variable "private_subnet_endpoints" {
  default = []
}

resource "azurerm_subnet" "app_private" {
  name                 = "${local.prefix}-app-private"
  resource_group_name  = var.rg_dataplane
  virtual_network_name = azurerm_virtual_network.app_vnet.name
  address_prefixes     = [cidrsubnet(var.cidr_dataplane, 6, 1)]

  private_endpoint_network_policies             = "Enabled"
  private_link_service_network_policies_enabled = true

  delegation {
    name = "databricks"
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
      "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"]
    }
  }

  service_endpoints = var.private_subnet_endpoints
}

resource "azurerm_subnet_network_security_group_association" "app_private" {
  # provider                  = azurerm.app
  subnet_id                 = azurerm_subnet.app_private.id
  network_security_group_id = azurerm_network_security_group.app_sg.id
}

resource "azurerm_subnet" "app_plsubnet" {
  # provider                                  = azurerm.app
  name                              = "${local.prefix}-app-privatelink"
  resource_group_name               = var.rg_dataplane
  virtual_network_name              = azurerm_virtual_network.app_vnet.name
  address_prefixes                  = [cidrsubnet(var.cidr_dataplane, 6, 2)]
  private_endpoint_network_policies = "Enabled"
}


