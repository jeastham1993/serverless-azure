build-orders:
	cd src/Dapr.Order.Api;az acr build -t ${ACR_REGISTRY}.azurecr.io/orders:${VERSION} -r ${ACR_REGISTRY} --platform linux/amd64  .

build-payments:
	cd src/Dapr.PaymentProcessor;az acr build -t ${ACR_REGISTRY}.azurecr.io/payments:${VERSION} -r ${ACR_REGISTRY} --platform linux/amd64  .

build-orders-local:
	cd src/Dapr.Order.Api;docker build -t orders  .

deploy-infra:
	cd infra;terraform apply --var-file dev.tfvars