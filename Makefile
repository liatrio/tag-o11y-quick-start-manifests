# we use --prune to clean up orphaned config maps.  Opted to keep the suffix hash Kustomize adds to generated config maps
# so changes to the config maps trigger a pod rollout and there's no need to manually restart them to get the new config

# also adding the sleep commands to allow the webhooks to become ready before applying the resources that rely on them
# https://github.com/cert-manager/cert-manager/issues/1873  https://github.com/cert-manager/cert-manager/pull/4171
apply-all:
	kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.4/cert-manager.yaml
	@sleep 90
	kubectl apply -k ./otel-operator
	@sleep 20
	kubectl apply -k ./gateway-collector/overlays/local/
	kubectl apply -k ./gateway-collector/overlays/local/ --prune -l app=grafana -l app=otel-collector --prune-allowlist core/v1/ConfigMap
apply-cert-manager:
	kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.4/cert-manager.yaml
apply-operator:
	kubectl apply -k ./otel-operator
apply-collector:
	kubectl apply -k ./gateway-collector/overlays/local/


delete-all:
	kubectl delete -k ./gateway-collector/overlays/local/
	kubectl delete -k ./otel-operator
	kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.4/cert-manager.yaml
delete-operator:
	kubectl delete -k ./otel-operator
delete-collector:
	kubectl delete -k ./gateway-collector/overlays/local/
delete-cert-manager:
	kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.4/cert-manager.yaml
