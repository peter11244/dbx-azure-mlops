module "auth_workspace" {
  source = "../modules/databricks-workspace"

  workspace_name        = "${local.prefix}-transit-workspace"
  resource_group_name   = local.rg_transit
  location              = var.location
  vnet_id               = data.terraform_remote_state.phase1_state.outputs.transit_vnet_id
  public_subnet_name    = data.terraform_remote_state.phase1_state.outputs.subnet_transit_public_name
  private_subnet_name   = data.terraform_remote_state.phase1_state.outputs.subnet_transit_private_name
  public_subnet_nsg_id  = data.terraform_remote_state.phase1_state.outputs.nsg_transit_public_id
  private_subnet_nsg_id = data.terraform_remote_state.phase1_state.outputs.nsg_transit_private_id
  storage_account_name  = local.dbfsname
  tags                  = local.tags
}


###
## Frontend Private Endpoint
###

module "front_pe" {
  source = "../modules/databricks-private-endpoint"

  name                = "frontprivatendpoint"
  location            = var.location
  resource_group_name = local.rg_transit
  subnet_id           = data.terraform_remote_state.phase1_state.outputs.transit_plsubnet_id
  workspace_id        = module.app_workspace.workspace_id
  subresource_name    = "databricks_ui_api"
  private_dns_zone_id = data.terraform_remote_state.phase1_state.outputs.dns_auth_front_id
  tags                = local.tags
}


module "transit_auth" {
  source = "../modules/databricks-private-endpoint"

  name                = "aadauthpvtendpoint-transit"
  location            = var.location
  resource_group_name = local.rg_transit
  subnet_id           = data.terraform_remote_state.phase1_state.outputs.transit_plsubnet_id
  workspace_id        = module.auth_workspace.workspace_id
  subresource_name    = "browser_authentication"
  private_dns_zone_id = data.terraform_remote_state.phase1_state.outputs.dns_auth_front_id
  tags                = local.tags
}
