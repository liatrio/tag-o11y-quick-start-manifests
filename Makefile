# we use --prune to clean up orphaned config maps.  Opted to keep the suffix hash Kustomize adds to generated config maps
# so changes to the config maps trigger a pod rollout and there's no need to manually restart them to get the new config
deploy:
	kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.4/cert-manager.yaml
	kubectl apply -k ./otel-operator
	kubectl apply -k ./gateway-collector/overlays/local/ --prune -l app=grafana --prune-allowlist core/v1/ConfigMap
destroy:
	kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.4/cert-manager.yaml
	kubectl delete -k ./otel-operator
	kubectl delete -k ./gateway-collector/overlays/local/