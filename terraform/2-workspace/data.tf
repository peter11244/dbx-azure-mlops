data "terraform_remote_state" "phase1_state" {
  backend = "azurerm"
  config = {
    tenant_id       = var.tenant_id
    subscription_id = var.subscription_id

    resource_group_name                     = var.phase_1_state_backend_resource_group_name
    storage_account_name                    = var.phase_1_state_backend_storage_account_name
    container_name                          = var.phase_1_state_backend_container_name
    key                                     = var.phase_1_state_backend_key_name
  }
}