resource "azurerm_container_app" "orders" {
  name                         = "orders"
  container_app_environment_id = data.azurerm_container_app_environment.env.id
  resource_group_name          = data.azurerm_resource_group.dapr_container_apps.name
  revision_mode                = "Single"
  dapr {
    app_id = "orders"
    app_port = 8080
    app_protocol = "http"
  }
  registry {
    server = data.azurerm_container_registry.orders_service_acr.login_server
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
      image  = "${var.container_registry_name}.azurecr.io/orders:${var.orders_application_version}"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name = "OrdersDbConnectionString"
        value = var.db_connection_string
      }
      env {
        name = "MOMENTO_API_KEY"
        value = var.momento_api_key
      }
      env {
        name = "DD_TRACE_OTEL_ENABLED"
        value = "true"
      }
      env {
        name = "DD_RUNTIME_METRICS_ENABLED"
        value = "true"
      }
      env {
        name = "DD_LOGS_INJECTION"
        value = "true"
      }
      env {
        name = "DD_ENV"
        value = var.env
      }
      env {
        name = "OTEL_EXPORTER_OTLP_ENDPOINT"
        value = "http://localhost:4317"
      }
    }
    container {
      name   = "datadog"
      image  = "index.docker.io/datadog/serverless-init:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name = "DD_SITE"
        value = var.dd_site
      }
      env {
        name = "DD_ENV"
        value = var.env
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
        name = "DD_AZURE_SUBSCRIPTION_ID"
        value = data.azurerm_subscription.primary.subscription_id
      }
      env {
        name = "DD_AZURE_RESOURCE_GROUP"
        value = data.azurerm_resource_group.dapr_container_apps.name
      }
      env {
        name = "DD_OTLP_CONFIG_RECEIVER_PROTOCOLS_GRPC_ENDPOINT"
        value = "0.0.0.0:4317"
      }
      env {
        name = "DD_APM_IGNORE_RESOURCES"
        value = "/opentelemetry.proto.collector.trace.v1.TraceService/Export$"
      }
    }
  }
  depends_on = [ azurerm_role_assignment.payments_app_acr_identity_role_assignment ]
}