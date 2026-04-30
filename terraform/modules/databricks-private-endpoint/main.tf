resource "azurerm_private_endpoint" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "ple-${var.name}"
    private_connection_resource_id = var.workspace_id
    is_manual_connection           = false
    subresource_names              = [var.subresource_name]
  }

  private_dns_zone_group {
    name                 = "${var.name}-dns-zone-group"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}
