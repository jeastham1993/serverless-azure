check-env:
ifndef ACR_REGISTRY
	$(error ACR_REGISTRY is undefined)
endif
ifndef VERSION
	$(error VERSION is undefined)
endif

build-orders: check-env
	cd src/Dapr.Order.Api;az acr build -t ${ACR_REGISTRY}.azurecr.io/orders:${VERSION} -r ${ACR_REGISTRY} --platform linux/amd64  .

build-payments: check-env
	cd src/Dapr.PaymentProcessor;az acr build -t ${ACR_REGISTRY}.azurecr.io/payments:${VERSION} -r ${ACR_REGISTRY} --platform linux/amd64  .

build-orders-local:
	cd src/Dapr.Order.Api;docker build -t orders  .

deploy-env-infra: check-env
	cd infra/environment;terraform init;terraform apply --var-file dev.tfvars

deploy-payments: check-env
	cd infra/payments;terraform init;terraform apply --var-file dev.tfvars

deploy-orders: check-env
	cd infra/orders;terraform apply --var-file dev.tfvars

destroy-infra:
	cd infra;terraform destroy --var-file dev.tfvars