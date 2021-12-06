NAMESPACE := greeter

.PHONY: all
all: infrastructure docker deployment
	@echo "\n\nAll setup, you can get the public IP address of the application by running:\n"
	@echo " kubectl -n istio-system get svc istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'"

.PHONY: infrastructure
infrastructure:
	cd terraform && terraform init
	cd terraform && terraform apply -auto-approve
	az aks get-credentials --name greeter-app --resource-group greeter-app --admin --overwrite-existing
	

.PHONY: docker
docker:
	docker build -t greeter.azurecr.io/app/greeter-app:latest .
	az acr login --name greeter
	docker push greeter.azurecr.io/app/greeter-app:latest

.PHONY: deployment
deployment:
	istioctl install -y
	
	kubectl create ns $(NAMESPACE) -o yaml | kubectl apply -f-
	kubectl label ns greeter istio-injection=enabled --overwrite
	helm install greeter-app ./k8s -n $(NAMESPACE)

.PHONY: clean-infrastructure
clean-infrastructure:
	cd terraform && terraform destroy -auto-approve

.PHONY: clean-deployment
clean-deployment:
	helm delete greeter-app -n $(NAMESPACE)
	kubectl delete ns $(NAMESPACE)
	istioctl x uninstall --purge -y
	kubectl delete ns istio-system

.PHONY: clean
clean: clean-deployment clean-infrastructure
	@echo "All cleaned, have a good day!"