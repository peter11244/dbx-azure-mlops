######################
##   REMOTE STATE   ##
######################

# Create a storage account to store the Terraform state file. This is a one-time operation.


resource "random_id" "storage_account" {
      byte_length = 8
}


resource "azurerm_storage_account" "tfstate" {
    name = "tfstate${lower(random_id.storage_account.hex)}"
    location = var.location
    resource_group_name = var.rg_tfstate
    account_tier = "Standard"
    account_replication_type = var.tfstate_account_replication_type
    is_hns_enabled = true
}

resource "azurerm_storage_container" "tfstate" {
    name = "tfstate"
    storage_account_name = azurerm_storage_account.tfstate.name
}