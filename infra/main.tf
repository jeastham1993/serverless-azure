resource "azurerm_resource_group" "dapr_container_apps" {
  name     = "dapr-container-apps"
  location = "West Europe"

  tags = {
    source = "terraform"
    env = "dev"
  }
}

resource "azurerm_log_analytics_workspace" "dapr_container_apps_log_analytics" {
  name                = "dapr-container-apps-logs"
  location            = azurerm_resource_group.dapr_container_apps.location
  resource_group_name = azurerm_resource_group.dapr_container_apps.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "dapr_container_apps_dev_environment" {
  name                       = "dev"
  location                   = azurerm_resource_group.dapr_container_apps.location
  resource_group_name        = azurerm_resource_group.dapr_container_apps.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.dapr_container_apps_log_analytics.id
  tags = {
    source = "terraform"
    env = "dev"
  }
}

resource "azurerm_servicebus_namespace" "public_service_bus_namespace" {
  name                = "jeasthampublic"
  location            = azurerm_resource_group.dapr_container_apps.location
  resource_group_name = azurerm_resource_group.dapr_container_apps.name
  sku                 = "Standard"

  tags = {
    source = "terraform"
    env = "dev"
  }
}

resource "azurerm_servicebus_namespace" "orders_service_bus_namespace" {
  name                = "jeasthamorders"
  location            = azurerm_resource_group.dapr_container_apps.location
  resource_group_name = azurerm_resource_group.dapr_container_apps.name
  sku                 = "Standard"

  tags = {
    source = "terraform"
    env = "dev"
  }
}

resource "azurerm_servicebus_topic" "order_created_topic" {
  name         = "ordercreated"
  namespace_id = azurerm_servicebus_namespace.orders_service_bus_namespace.id
}

resource "azurerm_servicebus_topic" "order_created_public_topic" {
  name         = "orders.ordercreated.v1"
  namespace_id = azurerm_servicebus_namespace.public_service_bus_namespace.id
}

resource "azurerm_user_assigned_identity" "orders_app_identity" {
  location            = azurerm_resource_group.dapr_container_apps.location
  name                = "ordersAppIdentity"
  resource_group_name = azurerm_resource_group.dapr_container_apps.name
}

resource "azurerm_user_assigned_identity" "payments_app_identity" {
  location            = azurerm_resource_group.dapr_container_apps.location
  name                = "paymentsAppIdentity"
  resource_group_name = azurerm_resource_group.dapr_container_apps.name
}

resource "azurerm_role_assignment" "orders_public_app_identity_role_assignment" {
  scope                = azurerm_servicebus_namespace.public_service_bus_namespace.id
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = azurerm_user_assigned_identity.orders_app_identity.principal_id
}

resource "azurerm_role_assignment" "orders_public_app_identity_receiver_role_assignment" {
  scope                = azurerm_servicebus_namespace.public_service_bus_namespace.id
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id         = azurerm_user_assigned_identity.orders_app_identity.principal_id
}

resource "azurerm_role_assignment" "orders_app_identity_role_assignment" {
  scope                = azurerm_servicebus_namespace.orders_service_bus_namespace.id
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = azurerm_user_assigned_identity.orders_app_identity.principal_id
}

resource "azurerm_role_assignment" "orders_app_identity_receiver_role_assignment" {
  scope                = azurerm_servicebus_namespace.orders_service_bus_namespace.id
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id         = azurerm_user_assigned_identity.orders_app_identity.principal_id
}

resource "azurerm_role_assignment" "orders_app_acr_identity_role_assignment" {
  scope                = azurerm_container_registry.orders_service_acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.orders_app_identity.principal_id
}

# resource "azurerm_role_assignment" "payments_public_app_identity_role_assignment" {
#   scope                = azurerm_servicebus_namespace.public_service_bus_namespace.id
#   role_definition_name = "Azure Service Bus Data Sender"
#   principal_id         = azurerm_user_assigned_identity.payments_app_identity.principal_id
# }

# resource "azurerm_role_assignment" "payments_public_app_identity_receiver_role_assignment" {
#   scope                = azurerm_servicebus_namespace.public_service_bus_namespace.id
#   role_definition_name = "Azure Service Bus Data Receiver"
#   principal_id         = azurerm_user_assigned_identity.payments_app_identity.principal_id
# }

resource "azurerm_role_assignment" "payments_app_acr_identity_role_assignment" {
  scope                = azurerm_container_registry.orders_service_acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.payments_app_identity.principal_id
}

resource "azurerm_container_registry" "orders_service_acr" {
  name                = "jeasthamdaprcontainerapps"
  resource_group_name = azurerm_resource_group.dapr_container_apps.name
  location            = azurerm_resource_group.dapr_container_apps.location
  sku                 = "Basic"
}

resource "azurerm_container_app_environment_dapr_component" "orders_topics" {
  name                         = "orders"
  container_app_environment_id = azurerm_container_app_environment.dapr_container_apps_dev_environment.id
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

resource "azurerm_container_app_environment_dapr_component" "order_created_public_topics" {
  name                         = "public"
  container_app_environment_id = azurerm_container_app_environment.dapr_container_apps_dev_environment.id
  component_type               = "pubsub.azure.servicebus.topics"
  version                      = "v1"
  scopes = [ "orders", "payments" ]
  metadata {
    name = "namespaceName"
    value = "${azurerm_servicebus_namespace.public_service_bus_namespace.name}.servicebus.windows.net"
  }
  metadata {
    name = "azureClientId"
    value = azurerm_user_assigned_identity.orders_app_identity.client_id
  }
}

resource "azurerm_container_app" "orders" {
  name                         = "orders"
  container_app_environment_id = azurerm_container_app_environment.dapr_container_apps_dev_environment.id
  resource_group_name          = azurerm_resource_group.dapr_container_apps.name
  revision_mode                = "Single"
  dapr {
    app_id = "orders"
    app_port = 8080
    app_protocol = "http"
  }
  registry {
    server = azurerm_container_registry.orders_service_acr.login_server
    identity = azurerm_user_assigned_identity.orders_app_identity.id
  }
  identity {
    identity_ids = [ azurerm_user_assigned_identity.orders_app_identity.id ]
    type = "UserAssigned"
  }
  ingress {
    external_enabled = true
    target_port = 8080
    traffic_weight {
      percentage = 100
      latest_revision = true
    }
  }
  template {
    min_replicas = 1
    max_replicas = 1
    container {
      name   = "orders"
      image  = "jeasthamdaprcontainerapps.azurecr.io/orders:${var.orders_application_version}"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name = "DD_SITE"
        value = var.dd_site
      }
      env {
        name = "DD_API_KEY"
        value = var.dd_api_key
      }
      env {
        name = "DD_VERSION"
        value = var.orders_application_version
      }
      env {
        name = "DD_ENV"
        value = "dev"
      }
      env {
        name = "DD_SERVICE"
        value = "Dapr.Order.Api"
      }
      env {
        name = "DD_LOGS_ENABLED"
        value = "true"
      }
      env {
        name = "DD_LOGS_INJECTION"
        value = "true"
      }
      env {
        name = "DD_AZURE_SUBSCRIPTION_ID"
        value = data.azurerm_subscription.primary.subscription_id
      }
      env {
        name = "DD_AZURE_RESOURCE_GROUP"
        value = azurerm_resource_group.dapr_container_apps.name
      }
      env {
        name = "MOMENTO_API_KEY"
        value = var.momento_api_key
      }
    }
  }
  depends_on = [ azurerm_role_assignment.orders_app_acr_identity_role_assignment ]
}

resource "azurerm_container_app" "payments" {
  name                         = "payments"
  container_app_environment_id = azurerm_container_app_environment.dapr_container_apps_dev_environment.id
  resource_group_name          = azurerm_resource_group.dapr_container_apps.name
  revision_mode                = "Single"
  dapr {
    app_id = "payments"
    app_port = 8080
    app_protocol = "http"
  }
  registry {
    server = azurerm_container_registry.orders_service_acr.login_server
    identity = azurerm_user_assigned_identity.payments_app_identity.id
  }
  identity {
    identity_ids = [ azurerm_user_assigned_identity.payments_app_identity.id ]
    type = "UserAssigned"
  }
  ingress {
    external_enabled = true
    target_port = 8080
    traffic_weight {
      percentage = 100
      latest_revision = true
    }
  }
  template {
    min_replicas = 1
    max_replicas = 1
    container {
      name   = "payments"
      image  = "jeasthamdaprcontainerapps.azurecr.io/payments:${var.payments_application_version}"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name = "DD_SITE"
        value = var.dd_site
      }
      env {
        name = "DD_API_KEY"
        value = var.dd_api_key
      }
      env {
        name = "DD_VERSION"
        value = var.payments_application_version
      }
      env {
        name = "DD_ENV"
        value = "dev"
      }
      env {
        name = "DD_SERVICE"
        value = "Dapr.PaymentProcessor"
      }
      env {
        name = "DD_LOGS_ENABLED"
        value = "true"
      }
      env {
        name = "DD_LOGS_INJECTION"
        value = "true"
      }
      env {
        name = "DD_AZURE_SUBSCRIPTION_ID"
        value = data.azurerm_subscription.primary.subscription_id
      }
      env {
        name = "DD_AZURE_RESOURCE_GROUP"
        value = azurerm_resource_group.dapr_container_apps.name
      }
    }
  }
  depends_on = [ azurerm_role_assignment.orders_app_acr_identity_role_assignment ]
}
