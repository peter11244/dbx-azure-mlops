plugin "azurerm" {
  enabled = true
  version = "0.31.1"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

# Intentionally disabled: this is a teaching/demo project meant to be torn down;
# prevent_destroy on every data resource would break the learning experience.
rule "azurerm_resources_missing_prevent_destroy" {
  enabled = false
}
