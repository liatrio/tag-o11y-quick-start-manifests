# we use --prune to clean up orphaned config maps.  Opted to keep the suffix hash Kustomize adds to generated config maps
# so changes to the config maps trigger a pod rollout and there's no need to manually restart them to get the new config

default:
	kustomize build ./cert-manager/ | kubectl apply -f -
	kubectl wait --for condition=Available -n cert-manager deployment/cert-manager-webhook

	kustomize build ./otel-operator/ | kubectl apply -f -
	kubectl wait --for condition=Available -n opentelemetry-operator-system deployment/opentelemetry-operator-controller-manager
	
	kustomize build ./gateway-collector/overlays/basic/ | kubectl apply -f -

apply-default:
	@while ! kustomize build ./otel-operator/ | kubectl apply -f - ; do sleep 10; done 
	@while ! kustomize build ./gateway-collector/overlays/local/ | kubectl apply -f - ; do sleep 10; done 
	@kustomize build ./gateway-collector/overlays/local/ | kubectl apply -f - --prune -l app=grafana -l app=otel-collector --prune-allowlist core/v1/ConfigMap
	@echo "The command has been executed successfully. The Engineering Effectiveness Metrics Dashboard can be found at: http://localhost:3000"
apply-traces:
	@while ! kustomize build ./otel-operator/ | kubectl apply -f - ; do sleep 10; done 
	@if ! kubectl create -f https://github.com/flux-iac/tofu-controller/releases/download/v0.15.1/tf-controller.crds.yaml; then echo "Tofu Controller CRDS already installed"; fi
	@while ! kustomize build ./gateway-collector/overlays/local-traces/ | kubectl apply -f - ; do sleep 10; done 
	@kustomize build ./gateway-collector/overlays/local-traces/ | kubectl apply -f - --prune -l app=grafana -l app=otel-collector --prune-allowlist core/v1/ConfigMap
	@echo "The command has been executed successfully. The Tofu Controller Traces Dashboard can be found at: http://localhost:3000"

delete-default:
	kustomize build ./gateway-collector/overlays/local/ | kubectl delete --ignore-not-found -f - 
	kustomize build ./otel-operator/ | kubectl delete --ignore-not-found -f -
delete-traces:
	kubectl patch terraforms.infra.contrib.fluxcd.io demo -n flux-system -p '{"metadata":{"finalizers":null}}' --type=merge
	kustomize build ./gateway-collector/overlays/local-traces/ | kubectl delete --ignore-not-found -f - 
	kustomize build ./otel-operator/ | kubectl delete --ignore-not-found -f -
	kubectl delete -f https://github.com/flux-iac/tofu-controller/releases/download/v0.15.1/tf-controller.crds.yaml

delete-cert-manager:
	kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.4/cert-manager.yaml
delete-operator:
	kubectl delete -k ./otel-operator/upstream
delete-traces-collector:
	kustomize build ./gateway-collector/overlays/local-traces/ | kubectl delete -f - 
delete-default-collector:
	kustomize build ./gateway-collector/overlays/local/ | kubectl delete -f - 