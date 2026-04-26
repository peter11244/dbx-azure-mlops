#####################
##  COST BUDGETS   ##
#####################

resource "azurerm_consumption_budget_resource_group" "gateway" {
  name              = "budget-${local.rg_gateway}"
  resource_group_id = azurerm_resource_group.gateway.id
  amount            = var.monthly_budget_usd
  time_grain        = "Monthly"

  time_period {
    start_date = "2024-01-01T00:00:00Z"
  }

  notification {
    enabled       = true
    threshold     = 100
    operator      = "EqualTo"
    contact_roles = ["Owner"]
  }
}

resource "azurerm_consumption_budget_resource_group" "transit" {
  name              = "budget-${local.rg_transit}"
  resource_group_id = azurerm_resource_group.transit.id
  amount            = var.monthly_budget_usd
  time_grain        = "Monthly"

  time_period {
    start_date = "2024-01-01T00:00:00Z"
  }

  notification {
    enabled       = true
    threshold     = 100
    operator      = "EqualTo"
    contact_roles = ["Owner"]
  }
}

resource "azurerm_consumption_budget_resource_group" "dataplane" {
  name              = "budget-${local.rg_dataplane}"
  resource_group_id = azurerm_resource_group.dataplane.id
  amount            = var.monthly_budget_usd
  time_grain        = "Monthly"

  time_period {
    start_date = "2024-01-01T00:00:00Z"
  }

  notification {
    enabled       = true
    threshold     = 100
    operator      = "EqualTo"
    contact_roles = ["Owner"]
  }
}

resource "azurerm_consumption_budget_resource_group" "tfstate" {
  name              = "budget-${local.rg_tfstate}"
  resource_group_id = azurerm_resource_group.tfstate.id
  amount            = var.monthly_budget_usd
  time_grain        = "Monthly"

  time_period {
    start_date = "2024-01-01T00:00:00Z"
  }

  notification {
    enabled       = true
    threshold     = 100
    operator      = "EqualTo"
    contact_roles = ["Owner"]
  }
}
