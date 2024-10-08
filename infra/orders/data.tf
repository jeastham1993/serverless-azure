data "azurerm_subscription" "primary" {
}

data "azurerm_resource_group" "dapr_container_apps" {
  name = var.resource_group_name
}

data "azurerm_container_registry" "orders_service_acr" {
  name                = var.container_registry_name
  resource_group_name = var.resource_group_name
}

data "azurerm_container_app_environment" "env" {
  name                = var.env
  resource_group_name = var.resource_group_name
}