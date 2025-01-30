###
## RESOURCE GROUPS
###

resource "azurerm_resource_group" "transit" {
  name     = var.rg_transit
  location = var.location
}

resource "azurerm_resource_group" "dataplane" {
  name     = var.rg_dp
  location = var.location
}




###
## TRANSIT VNET
###

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

resource "azurerm_private_endpoint" "transit_auth" {
  name                = "aadauthpvtendpoint-transit"
  location            = var.location
  resource_group_name = var.rg_transit
  subnet_id           = azurerm_subnet.transit_plsubnet.id

  private_service_connection {
    name                           = "ple-${local.prefix}-auth"
    private_connection_resource_id = azurerm_databricks_workspace.web_auth_workspace.id
    is_manual_connection           = false
    subresource_names              = ["browser_authentication"]
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-auth"
    private_dns_zone_ids = [azurerm_private_dns_zone.dns_auth_front.id]
  }
}

resource "azurerm_databricks_workspace" "web_auth_workspace" {
  name                                  = "${local.prefix}-transit-workspace"
  resource_group_name                   = var.rg_transit
  location                              = var.location
  sku                                   = "premium"
  tags                                  = local.tags
  public_network_access_enabled         = false                    //use private endpoint
  network_security_group_rules_required = "NoAzureDatabricksRules" //use private endpoint
  customer_managed_key_enabled          = true
  custom_parameters {
    no_public_ip                                         = true
    virtual_network_id                                   = azurerm_virtual_network.transit_vnet.id
    private_subnet_name                                  = azurerm_subnet.transit_private.name
    public_subnet_name                                   = azurerm_subnet.transit_public.name
    public_subnet_network_security_group_association_id  = azurerm_subnet_network_security_group_association.transit_public.id
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.transit_private.id
    storage_account_name                                 = local.dbfsname
  }
  depends_on = [
    azurerm_subnet_network_security_group_association.transit_public,
    azurerm_subnet_network_security_group_association.transit_private
  ]
}


###
## Frontend Private Endpoint
###

resource "azurerm_private_endpoint" "front_pe" {
  name                = "frontprivatendpoint"
  location            = var.location
  resource_group_name = var.rg_transit
  subnet_id           = azurerm_subnet.transit_plsubnet.id

  private_service_connection {
    name                           = "ple-${local.prefix}-uiapi"
    private_connection_resource_id = azurerm_databricks_workspace.app_workspace.id
    is_manual_connection           = false
    subresource_names              = ["databricks_ui_api"]
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-uiapi"
    private_dns_zone_ids = [azurerm_private_dns_zone.dns_auth_front.id]
  }
}

###
## DATA PLANE VNET
### 

resource "azurerm_virtual_network" "app_vnet" {
  name                = "${local.prefix}-app-vnet"
  location            = var.location
  resource_group_name = var.rg_dp
  address_space       = [var.cidr_dp]
  tags                = local.tags
}

resource "azurerm_network_security_group" "app_sg" {
  name                = "${local.prefix}-app-nsg"
  location            = var.location
  resource_group_name = var.rg_dp
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
  resource_group_name         = var.rg_dp
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
  resource_group_name         = var.rg_dp
  network_security_group_name = azurerm_network_security_group.app_sg.name
}


###
## PRIVATE DNS
### 

resource "azurerm_private_dns_zone" "dnsdpcp" {
  name                = "privatelink.azuredatabricks.net"
  resource_group_name = var.rg_dp
}

resource "azurerm_private_dns_zone_virtual_network_link" "uiapidnszonevnetlink" {
  name                  = "dpcpvnetconnection"
  resource_group_name   = var.rg_dp
  private_dns_zone_name = azurerm_private_dns_zone.dnsdpcp.name
  virtual_network_id    = azurerm_virtual_network.app_vnet.id
}

###
## DATABRICKS WORKSPACE
###

resource "azurerm_subnet" "app_public" {
  name                 = "${local.prefix}-app-public"
  resource_group_name  = var.rg_dp
  virtual_network_name = azurerm_virtual_network.app_vnet.name
  address_prefixes     = [cidrsubnet(var.cidr_dp, 6, 0)]

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
  resource_group_name  = var.rg_dp
  virtual_network_name = azurerm_virtual_network.app_vnet.name
  address_prefixes     = [cidrsubnet(var.cidr_dp, 6, 1)]

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
  resource_group_name               = var.rg_dp
  virtual_network_name              = azurerm_virtual_network.app_vnet.name
  address_prefixes                  = [cidrsubnet(var.cidr_dp, 6, 2)]
  private_endpoint_network_policies = "Enabled"
}

resource "azurerm_databricks_workspace" "app_workspace" {
  name                                  = "${local.prefix}-app-workspace"
  resource_group_name                   = var.rg_dp
  location                              = var.location
  sku                                   = "premium"
  tags                                  = local.tags
  public_network_access_enabled         = false                    //use private endpoint
  network_security_group_rules_required = "NoAzureDatabricksRules" //use private endpoint
  customer_managed_key_enabled          = true
  custom_parameters {
    no_public_ip                                         = true
    virtual_network_id                                   = azurerm_virtual_network.app_vnet.id
    private_subnet_name                                  = azurerm_subnet.app_private.name
    public_subnet_name                                   = azurerm_subnet.app_public.name
    public_subnet_network_security_group_association_id  = azurerm_subnet_network_security_group_association.app_public.id
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.app_private.id
    storage_account_name                                 = "dbfsapphj32ui4"
  }

  depends_on = [
    azurerm_subnet_network_security_group_association.app_public,
    azurerm_subnet_network_security_group_association.app_private
  ]
}


###
## BACKEND PRIVATE ENDPOINT
###

resource "azurerm_private_endpoint" "app_dpcp" {
  name                = "dpcppvtendpoint"
  resource_group_name = var.rg_dp
  location            = var.location
  subnet_id           = azurerm_subnet.app_plsubnet.id

  private_service_connection {
    name                           = "ple-${local.prefix}-dpcp"
    private_connection_resource_id = azurerm_databricks_workspace.app_workspace.id
    is_manual_connection           = false
    subresource_names              = ["databricks_ui_api"]
  }

  private_dns_zone_group {
    name                 = "app-private-dns-zone-dpcp"
    private_dns_zone_ids = [azurerm_private_dns_zone.dnsdpcp.id]
  }
}
