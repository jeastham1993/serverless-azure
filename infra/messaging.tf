resource "azurerm_user_assigned_identity" "warpstream_identity" {
  location            = azurerm_resource_group.dapr_container_apps.location
  name                = "warpstreamIdentity"
  resource_group_name = azurerm_resource_group.dapr_container_apps.name
}

resource "azurerm_role_assignment" "warpstream_identity_role_assignment" {
  scope                = azurerm_storage_account.warpstream_storage_account.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = azurerm_user_assigned_identity.warpstream_identity.principal_id
}

resource "azurerm_storage_account" "warpstream_storage_account" {
  name                     = "jeasthamwarpstreamstorage"
  resource_group_name          = azurerm_resource_group.dapr_container_apps.name
  location                 = azurerm_resource_group.dapr_container_apps.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

resource "azurerm_container_app" "kafka" {
  name                         = "kafka"
  container_app_environment_id = azurerm_container_app_environment.dapr_container_apps_dev_environment.id
  resource_group_name          = azurerm_resource_group.dapr_container_apps.name
  revision_mode                = "Single"
  dapr {
    app_id = "kafka"
    app_port = 9092
    app_protocol = "http"
  }
  identity {
    identity_ids = [ azurerm_user_assigned_identity.warpstream_identity.id ]
    type = "UserAssigned"
  }
  ingress {
    external_enabled = true
    target_port = 9092
    traffic_weight {
      percentage = 100
      latest_revision = true
    }
  }
  template {
    min_replicas = 1
    max_replicas = 1
    container {
      name   = "warp"
      image  = "public.ecr.aws/warpstream-labs/warpstream_agent:latest"
      cpu    = 0.25
      memory = "0.5Gi"
      command = ["agent", "-bucketURL", "azblob://${azurerm_storage_account.warpstream_storage_account.name}", "-agentKey", var.warpstream_agent_key, "-region", "eu-central-1", "-defaultVirtualClusterID", var.warpstream_virtual_cluster_id]
      env {
        name = "AZURE_STORAGE_ACCOUNT"
        value = azurerm_storage_account.warpstream_storage_account.name
      }
    }
  }
}