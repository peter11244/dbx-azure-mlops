
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
    virtual_network_id                                   = data.terraform_remote_state.phase1_state.outputs.transit_vnet_id
    private_subnet_name                                  = data.terraform_remote_state.phase1_state.outputs.subnet_transit_private_name
    public_subnet_name                                   = data.terraform_remote_state.phase1_state.outputs.subnet_transit_public_name
    public_subnet_network_security_group_association_id  = data.terraform_remote_state.phase1_state.outputs.nsg_transit_public_id
    private_subnet_network_security_group_association_id = data.terraform_remote_state.phase1_state.outputs.nsg_transit_private_id
    storage_account_name                                 = local.dbfsname
  }
}


###
## Frontend Private Endpoint
###

resource "azurerm_private_endpoint" "front_pe" {
  name                = "frontprivatendpoint"
  location            = var.location
  resource_group_name = var.rg_transit
  subnet_id           = data.terraform_remote_state.phase1_state.outputs.transit_plsubnet_id

  private_service_connection {
    name                           = "ple-${local.prefix}-uiapi"
    private_connection_resource_id = azurerm_databricks_workspace.app_workspace.id
    is_manual_connection           = false
    subresource_names              = ["databricks_ui_api"]
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-uiapi"
    private_dns_zone_ids = [data.terraform_remote_state.phase1_state.outputs.dns_auth_front_id]
  }
}


resource "azurerm_private_endpoint" "transit_auth" {
  name                = "aadauthpvtendpoint-transit"
  location            = var.location
  resource_group_name = var.rg_transit
  subnet_id           = data.terraform_remote_state.phase1_state.outputs.transit_plsubnet_id

  private_service_connection {
    name                           = "ple-${local.prefix}-auth"
    private_connection_resource_id = azurerm_databricks_workspace.web_auth_workspace.id
    is_manual_connection           = false
    subresource_names              = ["browser_authentication"]
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-auth"
    private_dns_zone_ids = [data.terraform_remote_state.phase1_state.outputs.dns_auth_front_id]
  }
}




