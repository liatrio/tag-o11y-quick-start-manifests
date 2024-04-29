# we use --prune to clean up orphaned config maps.  Opted to keep the suffix hash Kustomize adds to generated config maps
# so changes to the config maps trigger a pod rollout and there's no need to manually restart them to get the new config

apply = kubectl apply -k $1
delete = kubectl delete -k $1
urls = @echo "\
	Grafana: http://localhost:3000\n\
	Loki: http://localhost:3100\n\
	Tempo: http://localhost:4317\n\
	Prometheus: http://localhost:9090\
"

.PHONY: default
default: cert-manager otel-operator
	kubectl apply -k ./collectors/gateway/
	kubectl wait --timeout=120s --for condition=Available -n collector deployment/grafana
	$(call urls)

.PHONY: %-silent
%-silent:
	@$(MAKE) $* > /dev/null

.PHONY: cert-manager
cert-manager:
	# kubectl apply -k ./cluster-infra/cert-manager/
	kustomize build ./cluster-infra/cert-manager/ | kubectl apply -f -
	kubectl wait --for condition=Available -n cert-manager deployment/cert-manager
	kubectl wait --for condition=Available -n cert-manager deployment/cert-manager-cainjector
	kubectl wait --for condition=Available -n cert-manager deployment/cert-manager-webhook

.PHONY: otel-operator
otel-operator:
	kubectl apply -k ./cluster-infra/otel-operator/
	kubectl wait --for condition=Available -n otel-operator deployment/opentelemetry-operator-controller-manager

apply-basic:
	@kustomize build ./cert-manager/ | kubectl apply -f -
	@kubectl wait --for condition=Available -n cert-manager deployment/cert-manager-webhook

	@while ! kustomize build ./otel-operator/ | kubectl apply -f - ; do sleep 10; done 
	@kubectl wait --timeout=180s --for condition=Available -n opentelemetry-operator-system deployment/opentelemetry-operator-controller-manager
	@while ! kustomize build ./gateway-collector/overlays/basic/ | kubectl apply -f - ; do sleep 10; done 
	@kubectl wait --timeout=120s --for condition=Available -n collector deployment/grafana
	@echo "The command has been executed successfully. Your Grafana instance can be found at: http://localhost:3000"

apply-default:
	@kustomize build ./cert-manager/ | kubectl apply -f -
	@kubectl wait --timeout=60s --for condition=Available -n cert-manager deployment/cert-manager-webhook
	@while ! kustomize build ./otel-operator/ | kubectl apply -f - ; do sleep 10; done 
	@kubectl wait --timeout=180s --for condition=Available -n opentelemetry-operator-system deployment/opentelemetry-operator-controller-manager
	@while ! kustomize build ./gateway-collector/overlays/local/ | kubectl apply -f - ; do sleep 10; done 
	@kustomize build ./gateway-collector/overlays/local/ | kubectl apply -f - --prune -l app=grafana -l app=otel-collector --prune-allowlist core/v1/ConfigMap
	@kubectl wait --timeout=120s --for condition=Available -n collector deployment/grafana
	@echo "The command has been executed successfully. The Engineering Effectiveness Metrics Dashboard can be found at: http://localhost:3000"
apply-traces:
	@kustomize build ./cert-manager/ | kubectl apply -f -
	@while ! kustomize build ./otel-operator/ | kubectl apply -f - ; do sleep 10; done 
	@if ! kubectl create -f https://github.com/flux-iac/tofu-controller/releases/download/v0.15.1/tf-controller.crds.yaml; then echo "Tofu Controller CRDS already installed"; fi
	@while ! kustomize build ./gateway-collector/overlays/local-traces/ | kubectl apply -f - ; do sleep 10; done 
	@kustomize build ./gateway-collector/overlays/local-traces/ | kubectl apply -f - --prune -l app=grafana -l app=otel-collector --prune-allowlist core/v1/ConfigMap
	@kubectl wait --timeout=120s --for condition=Available -n collector deployment/grafana
	@echo "The command has been executed successfully. The Tofu Controller Traces Dashboard can be found at: http://localhost:3000"

delete-basic:
	kustomize build ./gateway-collector/overlays/basic/ | kubectl delete -f - --wait=true
	kustomize build ./otel-operator/ | kubectl delete -f - --wait=true
	kustomize build ./cert-manager/ | kubectl delete -f - --wait=true

delete-default:
	kustomize build ./cert-manager/ | kubectl delete --ignore-not-found -f -
	kustomize build ./otel-operator/ | kubectl delete --ignore-not-found -f -
	kustomize build ./gateway-collector/overlays/local/ | kubectl delete --ignore-not-found -f - 

delete-traces:
	kubectl patch terraforms.infra.contrib.fluxcd.io demo -n flux-system -p '{"metadata":{"finalizers":null}}' --type=merge
	kustomize build ./gateway-collector/overlays/local-traces/ | kubectl delete --ignore-not-found -f - 
	kustomize build ./otel-operator/ | kubectl delete --ignore-not-found -f -
	kubectl delete -f https://github.com/flux-iac/tofu-controller/releases/download/v0.15.1/tf-controller.crds.yaml
	kustomize build ./cert-manager/ | kubectl delete --ignore-not-found -f -


delete-cert-manager:
	kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.4/cert-manager.yaml
delete-operator:
	kubectl delete -k ./otel-operator/upstream
delete-traces-collector:
	kustomize build ./gateway-collector/overlays/local-traces/ | kubectl delete -f - 
delete-default-collector:
	kustomize build ./gateway-collector/overlays/local/ | kubectl delete -f - 