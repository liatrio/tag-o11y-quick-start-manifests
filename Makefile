deploy:
	kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.4/cert-manager.yaml
	kubectl apply -k ./otel-operator
	kubectl apply -k ./gateway-collector/overlays/local/
destroy:
	kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.4/cert-manager.yaml
	kubectl delete -k ./otel-operator
	kubectl delete -k ./gateway-collector/overlays/local/