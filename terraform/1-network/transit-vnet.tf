####################
##  TRANSIT VNET  ##
####################

# The transit VNet is the network that allows access for users to the Databricks workspace.
# It contains a Private DNS Zone, private endpoints, and an authentication workspace.

resource "azurerm_virtual_network" "transit_vnet" {
  name                = "${local.prefix}-transit-vnet"
  location            = var.location
  resource_group_name = var.rg_transit
  address_space       = [var.cidr_transit]
  tags                = local.tags
}

resource "azurerm_network_security_group" "transit_sg" {
  name                = "${local.prefix}-transit-nsg"
  location            = var.location
  resource_group_name = var.rg_transit
  tags                = local.tags
}

resource "azurerm_network_security_rule" "transit_aad" {
  name                        = "AllowAAD-transit"
  priority                    = 200
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "AzureActiveDirectory"
  resource_group_name         = var.rg_transit
  network_security_group_name = azurerm_network_security_group.transit_sg.name
}

resource "azurerm_network_security_rule" "transit_azfrontdoor" {
  name                        = "AllowAzureFrontDoor-transit"
  priority                    = 201
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "AzureFrontDoor.Frontend"
  resource_group_name         = var.rg_transit
  network_security_group_name = azurerm_network_security_group.transit_sg.name
}

###
## PRIVATE DNS ZONE
###

resource "azurerm_private_dns_zone" "dns_auth_front" {
  name                = "privatelink.azuredatabricks.net"
  resource_group_name = var.rg_transit
}

resource "azurerm_private_dns_zone_virtual_network_link" "transitdnszonevnetlink" {
  name                  = "dpcpspokevnetconnection"
  resource_group_name   = var.rg_transit
  private_dns_zone_name = azurerm_private_dns_zone.dns_auth_front.name
  virtual_network_id    = azurerm_virtual_network.transit_vnet.id
}


###
## Web Auth Workspace
###

resource "azurerm_subnet" "transit_public" {
  name                 = "${local.prefix}-transit-public"
  resource_group_name  = var.rg_transit
  virtual_network_name = azurerm_virtual_network.transit_vnet.name
  address_prefixes     = [cidrsubnet(var.cidr_transit, 6, 0)]

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

resource "azurerm_subnet_network_security_group_association" "transit_public" {
  subnet_id                 = azurerm_subnet.transit_public.id
  network_security_group_id = azurerm_network_security_group.transit_sg.id
}

variable "transit_private_subnet_endpoints" {
  default = []
}

resource "azurerm_subnet" "transit_private" {
  name                 = "${local.prefix}-transit-private"
  resource_group_name  = var.rg_transit
  virtual_network_name = azurerm_virtual_network.transit_vnet.name
  address_prefixes     = [cidrsubnet(var.cidr_transit, 6, 1)]

  private_endpoint_network_policies = "Enabled"
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

  service_endpoints = var.transit_private_subnet_endpoints
}


resource "azurerm_subnet_network_security_group_association" "transit_private" {
  subnet_id                 = azurerm_subnet.transit_private.id
  network_security_group_id = azurerm_network_security_group.transit_sg.id
}


resource "azurerm_subnet" "transit_plsubnet" {
  name                              = "${local.prefix}-transit-privatelink"
  resource_group_name               = var.rg_transit
  virtual_network_name              = azurerm_virtual_network.transit_vnet.name
  address_prefixes                  = [cidrsubnet(var.cidr_transit, 6, 2)]
  private_endpoint_network_policies = "Enabled"
}

