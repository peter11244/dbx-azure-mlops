resource "azurerm_databricks_workspace" "app_workspace" {
  name                                  = "${local.prefix}-app-workspace"
  resource_group_name                   = var.rg_dataplane
  location                              = var.location
  sku                                   = "premium"
  tags                                  = local.tags
  public_network_access_enabled         = false                    //use private endpoint
  network_security_group_rules_required = "NoAzureDatabricksRules" //use private endpoint
  customer_managed_key_enabled          = true
  custom_parameters {
    no_public_ip                                         = true
    virtual_network_id                                   = data.terraform_remote_state.phase1_state.outputs.app_vnet_id
    private_subnet_name                                  = data.terraform_remote_state.phase1_state.outputs.subnet_app_private_name
    public_subnet_name                                   = data.terraform_remote_state.phase1_state.outputs.subnet_app_public_name
    public_subnet_network_security_group_association_id  = data.terraform_remote_state.phase1_state.outputs.nsg_app_public_id
    private_subnet_network_security_group_association_id = data.terraform_remote_state.phase1_state.outputs.nsg_app_private_id
    storage_account_name                                 = "dbfsapphj32ui4"
  }
}

###
## BACKEND PRIVATE ENDPOINT
###

resource "azurerm_private_endpoint" "app_dpcp" {
  name                = "dpcppvtendpoint"
  resource_group_name = var.rg_dataplane
  location            = var.location
  subnet_id           = data.terraform_remote_state.phase1_state.outputs.subnet_app_plsubnet_id

  private_service_connection {
    name                           = "ple-${local.prefix}-dpcp"
    private_connection_resource_id = azurerm_databricks_workspace.app_workspace.id
    is_manual_connection           = false
    subresource_names              = ["databricks_ui_api"]
  }

  private_dns_zone_group {
    name                 = "app-private-dns-zone-dpcp"
    private_dns_zone_ids = [data.terraform_remote_state.phase1_state.outputs.private_dns_zone_dnsdpcp_id]
  }
}