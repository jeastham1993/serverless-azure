resource "azurerm_container_app_environment_dapr_component" "public_pubsub" {
  name                         = "public"
  container_app_environment_id = azurerm_container_app_environment.dapr_container_apps_dev_environment.id
  component_type               = "pubsub.kafka"
  version                      = "v1"
  scopes = [ "orders", "payments" ]
  metadata {
    name = "brokers"
    value = var.kafka_broker
  }
  metadata {
    name = "authType"
    value = "password"
  }
  metadata {
    name = "saslUsername"
    value = var.kafka_username
  }
  metadata {
    name = "saslPassword"
    value = var.kafka_password
  }
  metadata {
    name = "saslMechanism"
    value = "PLAINTEXT"
  }
}