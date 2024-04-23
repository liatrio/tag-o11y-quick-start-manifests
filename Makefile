# we use --prune to clean up orphaned config maps.  Opted to keep the suffix hash Kustomize adds to generated config maps
# so changes to the config maps trigger a pod rollout and there's no need to manually restart them to get the new config

# also adding the sleep commands to allow the webhooks to become ready before applying the resources that rely on them
# https://github.com/cert-manager/cert-manager/issues/1873  https://github.com/cert-manager/cert-manager/pull/4171
apply-default:
	kustomize build ./otel-operator/ | kubectl apply -f -
	@while ! kustomize build ./gateway-collector/overlays/local/ | kubectl apply -f - ; do sleep 10; done 
	kustomize build ./gateway-collector/overlays/local/ | kubectl apply -f - --prune -l app=grafana -l app=otel-collector --prune-allowlist core/v1/ConfigMap
	@echo "The command has been executed successfully. The Engineering Effectiveness Metrics Dashboard can be found at: http://localhost:3000"
apply-traces:
	kustomize build ./otel-operator/ | kubectl apply -f -
	@while ! kustomize build ./gateway-collector/overlays/local-traces/ | kubectl apply -f - ; do sleep 10; done 
	kustomize build ./gateway-collector/overlays/local-traces/ | kubectl apply -f - --prune -l app=grafana -l app=otel-collector --prune-allowlist core/v1/ConfigMap
	@echo "The command has been executed successfully. The Tofu Controller Traces Dashboard can be found at: http://localhost:3000"

delete-default:
	kustomize build ./gateway-collector/overlays/local/ | kubectl delete -f - 
	kustomize build ./otel-operator/ | kubectl delete -f -
delete-traces:
	kustomize build ./gateway-collector/overlays/local-traces/ | kubectl delete -f - 
	kustomize build ./otel-operator/ | kubectl delete -f -
delete-cert-manager:
	kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.4/cert-manager.yaml
delete-operator:
	kubectl delete -k ./otel-operator/upstream
delete-traces-collector:
	kustomize build ./gateway-collector/overlays/local-traces/ | kubectl delete -f - 
delete-default-collector:
	kustomize build ./gateway-collector/overlays/local/ | kubectl delete -f - 