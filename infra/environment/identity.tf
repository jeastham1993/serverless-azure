resource "azurerm_user_assigned_identity" "public_service_bus_identity" {
  location            = azurerm_resource_group.dapr_container_apps.location
  name                = "publicPubSubIdentity-${var.env}"
  resource_group_name = azurerm_resource_group.dapr_container_apps.name
}

