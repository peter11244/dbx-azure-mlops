module "app_workspace" {
  source = "../modules/databricks-workspace"

  workspace_name        = "${local.prefix}-app-workspace"
  resource_group_name   = local.rg_dataplane
  location              = var.location
  vnet_id               = data.terraform_remote_state.phase1_state.outputs.app_vnet_id
  public_subnet_name    = data.terraform_remote_state.phase1_state.outputs.subnet_app_public_name
  private_subnet_name   = data.terraform_remote_state.phase1_state.outputs.subnet_app_private_name
  public_subnet_nsg_id  = data.terraform_remote_state.phase1_state.outputs.nsg_app_public_id
  private_subnet_nsg_id = data.terraform_remote_state.phase1_state.outputs.nsg_app_private_id
  storage_account_name  = "dbfsapphj32ui4"
  tags                  = local.tags
}

###
## BACKEND PRIVATE ENDPOINT
###

resource "azurerm_private_endpoint" "app_dpcp" {
  name                = "dpcppvtendpoint"
  resource_group_name = local.rg_dataplane
  location            = var.location
  subnet_id           = data.terraform_remote_state.phase1_state.outputs.subnet_app_plsubnet_id

  private_service_connection {
    name                           = "ple-${local.prefix}-dpcp"
    private_connection_resource_id = module.app_workspace.workspace_id
    is_manual_connection           = false
    subresource_names              = ["databricks_ui_api"]
  }

  private_dns_zone_group {
    name                 = "app-private-dns-zone-dpcp"
    private_dns_zone_ids = [data.terraform_remote_state.phase1_state.outputs.private_dns_zone_dnsdpcp_id]
  }
}
