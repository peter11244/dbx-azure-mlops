output "app_vnet_id" {
  value = azurerm_virtual_network.app_vnet.id
}
output "transit_vnet_id" {
  value = azurerm_virtual_network.transit_vnet.id
}
output "subnet_app_private_name" {
  value = azurerm_subnet.app_private.name
}
output "subnet_app_public_name" {
  value = azurerm_subnet.app_public.name
}
output "subnet_transit_private_name" {
  value = azurerm_subnet.transit_private.name
}
output "subnet_transit_public_name" {
  value = azurerm_subnet.transit_public.name
}
output "nsg_app_private_id" {
  value = azurerm_subnet_network_security_group_association.app_private.id
}
output "nsg_app_public_id" {
  value = azurerm_subnet_network_security_group_association.app_public.id
}
output "nsg_transit_private_id" {
  value = azurerm_subnet_network_security_group_association.transit_private.id
}
output "nsg_transit_public_id" {
  value = azurerm_subnet_network_security_group_association.transit_public.id
}
output "subnet_app_plsubnet_id" {
  value = azurerm_subnet.app_plsubnet.id
}
output "private_dns_zone_dnsdpcp_id" {
  value = azurerm_private_dns_zone.dnsdpcp.id
}
output "dns_auth_front_id" {
  value = azurerm_private_dns_zone.dns_auth_front.id
}
output "transit_plsubnet_id" {
  value = azurerm_subnet.transit_plsubnet.id
}
