#######################
##  Gateway Network  ##
#######################

# Create a new resource group for the gateway network. 
# This will contain the virtual network, subnets, and gateway resources.
# The gateway allows P2S VPN connections to the network, and therefore
# access to the data plane resources.  


resource "azurerm_virtual_network" "gateway" {
  name                = "vnet-dbx-ml-gateway"
  resource_group_name = var.rg_gateway
  location            = var.location
  address_space       = [var.cidr_gateway]
}

resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name = var.rg_gateway
  virtual_network_name = azurerm_virtual_network.gateway.name
  address_prefixes     = [cidrsubnet(var.cidr_gateway, 8, 0)]
}

resource "azurerm_subnet" "resolver" {
  name                 = "ResolverSubnet"
  resource_group_name = var.rg_gateway
  virtual_network_name = azurerm_virtual_network.gateway.name
  address_prefixes     = [cidrsubnet(var.cidr_gateway, 8, 1)]

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
  resource_group_name = var.rg_gateway
  location            = var.location
  allocation_method   = "Static"
}

resource "azurerm_virtual_network_gateway" "gateway" {
  name                = "vng-dbx-ml-gateway"
  resource_group_name = var.rg_gateway
  location            = var.location
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
    address_space = [var.cidr_vpn_gateway]
    
    vpn_client_protocols = [ "OpenVPN" ] # Must use with AAD
    vpn_auth_types = [ "AAD" ]
    aad_tenant = "https://login.microsoftonline.com/${var.tenant_id}/"
    aad_audience = "41b23e61-6c1e-4545-b367-cd054e0ed4b4"
    aad_issuer = "https://sts.windows.net/${var.tenant_id}/"
    
    
  }

  custom_route {
    address_prefixes = [ var.cidr_gateway, var.cidr_transit ]
  }

}

resource "azurerm_private_dns_resolver" "gateway" {
  name = "pr-vnet-gateway"
  resource_group_name = var.rg_gateway
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
  resource_group_name       = var.rg_gateway
  virtual_network_name      = azurerm_virtual_network.gateway.name
  remote_virtual_network_id = azurerm_virtual_network.transit_vnet.id
  allow_gateway_transit = true
}


resource "azurerm_virtual_network_peering" "transit-gateway" {
  name                      = "dbxtransit-gateway"
  resource_group_name       = var.rg_transit
  virtual_network_name      = azurerm_virtual_network.transit_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.gateway.id
  use_remote_gateways = true
  allow_forwarded_traffic = true
}

resource "azurerm_private_dns_zone_virtual_network_link" "gateway" {
    name                  = "dnslink-transit-gateway"
    resource_group_name   = var.rg_transit
    private_dns_zone_name = azurerm_private_dns_zone.dns_auth_front.name
    virtual_network_id    = azurerm_virtual_network.gateway.id  
}