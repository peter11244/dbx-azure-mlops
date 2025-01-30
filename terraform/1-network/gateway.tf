resource "azurerm_resource_group" "gateway" {
  name     = "rg-dbx-ml-gateway"
  location = var.location
}

resource "azurerm_virtual_network" "gateway" {
  name                = "vnet-dbx-ml-gateway"
  resource_group_name = azurerm_resource_group.gateway.name
  location            = azurerm_resource_group.gateway.location
  address_space       = ["10.255.0.0/16"]
}

resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.gateway.name
  virtual_network_name = azurerm_virtual_network.gateway.name
  address_prefixes     = ["10.255.255.0/24"]
}

resource "azurerm_subnet" "resolver" {
  name                 = "ResolverSubnet"
  resource_group_name  = azurerm_resource_group.gateway.name
  virtual_network_name = azurerm_virtual_network.gateway.name
  address_prefixes     = ["10.255.253.0/24"]

  delegation {
    name = "Microsoft.Network.dnsResolvers"
    service_delegation {
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      name    = "Microsoft.Network/dnsResolvers"
    }
  }
}

resource "azurerm_public_ip" "gateway" {
  name                = "ip-dbx-ml-gateway"
  resource_group_name = azurerm_resource_group.gateway.name
  location            = azurerm_resource_group.gateway.location
  allocation_method   = "Static"
}

resource "azurerm_virtual_network_gateway" "gateway" {
  name                = "vng-dbx-ml-gateway"
  resource_group_name = azurerm_resource_group.gateway.name
  location            = azurerm_resource_group.gateway.location
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw1"
  active_active       = false

  ip_configuration {
    name                          = "vng-dbx-ml-gateway-ipconfig"
    public_ip_address_id          = azurerm_public_ip.gateway.id
    subnet_id                     = azurerm_subnet.gateway.id
    private_ip_address_allocation = "Dynamic"
  }

  vpn_client_configuration {
    address_space = ["10.254.255.0/24"]
    
    vpn_client_protocols = [ "OpenVPN" ] # Must use with AAD
    vpn_auth_types = [ "AAD" ]
    aad_tenant = "https://login.microsoftonline.com/${var.tenant_id}/"
    aad_audience = "41b23e61-6c1e-4545-b367-cd054e0ed4b4"
    aad_issuer = "https://sts.windows.net/${var.tenant_id}/"
    
    
  }

  custom_route {
    address_prefixes = [ "10.255.0.0/16", "10.10.0.0/16" ]
  }

}

resource "azurerm_private_dns_resolver" "gateway" {
  name = "pr-vnet-gateway"
  resource_group_name = azurerm_resource_group.gateway.name
  location = var.location
  virtual_network_id = azurerm_virtual_network.gateway.id
}


resource "azurerm_private_dns_resolver_inbound_endpoint" "gateway" {
  name                    = "PE_RESOLVER_IB"
  private_dns_resolver_id = azurerm_private_dns_resolver.gateway.id
  location                = var.location
  ip_configurations {
    private_ip_allocation_method = "Dynamic"
    subnet_id                    = azurerm_subnet.resolver.id
  }
}

resource "azurerm_virtual_network_peering" "gateway-transit" {
  name                      = "gateway-dbxtransit"
  resource_group_name       = azurerm_resource_group.gateway.name
  virtual_network_name      = azurerm_virtual_network.gateway.name
  remote_virtual_network_id = azurerm_virtual_network.transit_vnet.id
}


resource "azurerm_virtual_network_peering" "transit-gateway" {
  name                      = "dbxtransit-gateway"
  resource_group_name       = azurerm_resource_group.transit.name
  virtual_network_name      = azurerm_virtual_network.transit_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.gateway.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "gateway" {
    name                  = "dnslink-transit-gateway"
    resource_group_name   = azurerm_resource_group.transit.name
    private_dns_zone_name = azurerm_private_dns_zone.dns_auth_front.name
    virtual_network_id    = azurerm_virtual_network.gateway.id
}