# Serverless on Azure

Building with the Azure serverless services.

## Prerequisites

- .NET 8
- [Dapr CLI](https://docs.dapr.io/getting-started/install-dapr-cli/)
- Docker, or Docker compatible tooling
- Existing Azure subscription with Storage Account created for storing Terraform state 
    - You'll need to update the 3 providers.tf files to set the correct storage account name

## Local Development

1. `docker-compose up -d`
2. `dapr run -f .`

## Deploy

1. Create `dev.tfvars` file under [`infra/environment`](infra/environment/)

```tf
subscription_id = ""
env = "dev"
dd_api_key = ""
dd_site = ""
kafka_broker=""
kafka_username=""
kafka_password=""
```

2. `make deploy-env-infra`
3. Go to created container app environment in the Azure Console and configure OTEL Endpoint for Datadog
4. `make build-orders`
5. Create `dev.tfvars` file under [`infra/orders`](infra/orders/)

```tf
orders_application_version=""
container_registry_name = ""
env = ""
resource_group_name = ""
dd_api_key = ""
dd_site = ""
momento_api_key = ""
db_connection_string = ""
subscription_id = ""
```

6. `deploy-orders`
7. `make build-payments`
6. Create `dev.tfvars` file under [`infra/payments`](infra/payments/)

```tf
payments_application_version=""
container_registry_name = ""
resource_group_name = ""
dd_api_key = ""
dd_site = ""
subscription_id = ""
env = ""
```

7. `deploy-orders`