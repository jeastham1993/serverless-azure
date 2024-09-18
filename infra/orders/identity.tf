resource "azurerm_user_assigned_identity" "orders_app_identity" {
  location            = data.azurerm_resource_group.dapr_container_apps.location
  name                = "ordersAppIdentity-${var.env}"
  resource_group_name = data.azurerm_resource_group.dapr_container_apps.name
}

resource "azurerm_role_assignment" "payments_app_acr_identity_role_assignment" {
  scope                = data.azurerm_container_registry.orders_service_acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.orders_app_identity.principal_id
}

resource "azurerm_role_assignment" "orders_service_bus_identity_assignment" {
  scope                = azurerm_servicebus_namespace.orders_service_bus_namespace.id
  role_definition_name = "Azure Service Bus Data Owner"
  principal_id         = azurerm_user_assigned_identity.orders_app_identity.principal_id
}