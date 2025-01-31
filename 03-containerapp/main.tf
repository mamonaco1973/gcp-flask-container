# Configure the AzureRM provider
provider "azurerm" {
  # Enables the default features of the provider
  features {}
}

# Data source to fetch details of the primary subscription
data "azurerm_subscription" "primary" {}

# Data source to fetch the details of the current Azure client
data "azurerm_client_config" "current" {}

# Resource group for the project

data "azurerm_resource_group" "flask_container_rg" {
  name = var.resource_group_name
}

data "azurerm_container_registry" "flask_acr" {
  name                = "flaskapp${substr(data.azurerm_client_config.current.subscription_id, 0, 6)}"
  resource_group_name = data.azurerm_resource_group.flask_container_rg.name
}
