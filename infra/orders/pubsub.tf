resource "azurerm_servicebus_namespace" "orders_service_bus_namespace" {
  name                = "jeasthamorders-${var.env}"
  location            = data.azurerm_resource_group.dapr_container_apps.location
  resource_group_name = data.azurerm_resource_group.dapr_container_apps.name
  sku                 = "Standard"

  tags = {
    source = "terraform"
    env = var.env
  }
}

resource "azurerm_servicebus_topic" "order_created_topic" {
  name         = "ordercreated"
  namespace_id = azurerm_servicebus_namespace.orders_service_bus_namespace.id
}

resource "azurerm_container_app_environment_dapr_component" "orders_topics" {
  name                         = "orders"
  container_app_environment_id = data.azurerm_container_app_environment.env.id
  component_type               = "pubsub.azure.servicebus.topics"
  version                      = "v1"
  scopes = [ "orders" ]
  metadata {
    name = "namespaceName"
    value = "${azurerm_servicebus_namespace.orders_service_bus_namespace.name}.servicebus.windows.net"
  }
  metadata {
    name = "azureClientId"
    value = azurerm_user_assigned_identity.orders_app_identity.client_id
  }
}