resource "azurerm_container_registry" "dapr_apps_acr" {
  name                = "jeasthamacr"
  resource_group_name = azurerm_resource_group.dapr_container_apps.name
  location            = azurerm_resource_group.dapr_container_apps.location
  sku                 = "Basic"
}

resource "azurerm_resource_group" "dapr_container_apps" {
  name     = "dapr-container-apps-${var.env}"
  location = "West Europe"
  tags = {
    source = "terraform"
    env = var.env
  }
}

resource "azurerm_log_analytics_workspace" "dapr_container_apps_log_analytics" {
  name                = "dapr-container-apps-logs-${var.env}"
  location            = azurerm_resource_group.dapr_container_apps.location
  resource_group_name = azurerm_resource_group.dapr_container_apps.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags = {
    source = "terraform"
    env = var.env
  }
}

resource "azurerm_container_app_environment" "dapr_container_apps_dev_environment" {
  name                       = var.env
  location                   = azurerm_resource_group.dapr_container_apps.location
  resource_group_name        = azurerm_resource_group.dapr_container_apps.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.dapr_container_apps_log_analytics.id
  tags = {
    source = "terraform"
    env = var.env
  }
}