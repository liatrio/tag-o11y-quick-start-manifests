# we use --prune to clean up orphaned config maps.  Opted to keep the suffix hash Kustomize adds to generated config maps
# so changes to the config maps trigger a pod rollout and there's no need to manually restart them to get the new config

apply = kubectl apply -k $1
delete = kubectl delete -k $1
urls = @echo "\
	Grafana: http://localhost:3000\n\
	Loki: http://localhost:3100\n\
	Tempo: http://localhost:4317\n\
	Prometheus: http://localhost:9090\n\
	Jaeger: http://localhost:16686\
"
NGROK_NS=ngrok-ingress
NGROK_AT = ${NGROK_AUTHTOKEN}
NGROK_AK = ${NGROK_API_KEY}

.PHONY: setup
setup:
	@chmod +x scripts/setup.sh
	@./scripts/setup.sh

.PHONY: check
check: setup

.PHONY: default
default:
	@echo "Checking prerequisites..."
	@if ! docker ps >/dev/null 2>&1; then \
		echo "ERROR: Docker is not running. Please start Docker Desktop first."; \
		exit 1; \
	fi
	@echo "Looking for otel-basic cluster..."; \
	cluster=$$(k3d cluster ls --no-headers otel-basic 2> /dev/null | awk '{print $$1}'); \
	if [[ "$$cluster" && $$cluster = "otel-basic" ]]; then \
		echo "otel-basic cluster present"; \
	else \
		echo "not present... creating otel-basic cluster"; \
		k3d cluster create otel-basic 1> /dev/null; \
	fi; \
	k3d kubeconfig write otel-basic; \
	export KUBECONFIG=$$HOME/.config/k3d/kubeconfig-otel-basic.yaml; \
	tilt up --file apps/Tiltfile; \

.PHONY: %-silent
%-silent:
	@$(MAKE) $* > /dev/null

.PHONY: cert-manager
cert-manager:
	kubectl apply -k ./cluster-infra/cert-manager/
	kubectl wait --for condition=Available -n cert-manager deployment/cert-manager
	kubectl wait --for condition=Available -n cert-manager deployment/cert-manager-cainjector
	kubectl wait --for condition=Available -n cert-manager deployment/cert-manager-webhook

.PHONY: otel-operator
otel-operator:
	kubectl apply -k ./cluster-infra/otel-operator/
	kubectl apply -k ./cluster-infra/rbac/
	kubectl wait --for condition=Available -n opentelemetry-operator-system deployment/opentelemetry-operator-controller-manager

.PHONY: jaeger-operator
jaeger-operator:
	kubectl apply -k ./cluster-infra/jaeger-operator/
	kubectl wait --for condition=Available -n observability deployment/jaeger-operator

.PHONY: gpr
gpr:
	kubectl apply -k ./collectors/gitproviderreceiver/

.PHONY: setup-github
setup-github:
	@chmod +x scripts/setup-github.sh
	@./scripts/setup-github.sh

.PHONY: setup-gitlab
setup-gitlab:
	@chmod +x scripts/setup-gitlab.sh
	@./scripts/setup-gitlab.sh

.PHONY: ghr deploy-github
ghr deploy-github:
	@if [ ! -f ./collectors/githubreceiver/.env ]; then \
		echo "ERROR: GitHub PAT not configured. Run 'make setup-github' first."; \
		exit 1; \
	fi
	@if [ ! -s ./collectors/githubreceiver/.env ]; then \
		echo "ERROR: GitHub PAT file exists but is empty. Run 'make setup-github' to configure it."; \
		exit 1; \
	fi
	@if ! grep -q "^GH_PAT=" ./collectors/githubreceiver/.env || grep -q "^GH_PAT=$$" ./collectors/githubreceiver/.env || grep -q "GH_PAT=YOUR_TOKEN_HERE" ./collectors/githubreceiver/.env; then \
		echo "ERROR: GitHub PAT is not set in .env file. Run 'make setup-github' to configure it."; \
		exit 1; \
	fi
	@echo "Applying GitHub receiver configuration..."
	@export KUBECONFIG=$$HOME/.config/k3d/kubeconfig-otel-basic.yaml; \
	echo "Building kustomize resources..."; \
	if ! kustomize build ./collectors/githubreceiver/ > /tmp/ghr-resources.yaml 2>&1; then \
		echo "ERROR: kustomize build failed. Check ./collectors/githubreceiver/.env file."; \
		exit 1; \
	fi; \
	echo "Applying resources..."; \
	if ! kubectl apply -f /tmp/ghr-resources.yaml; then \
		echo "ERROR: kubectl apply failed. Check cluster connectivity."; \
		exit 1; \
	fi; \
	echo "GitHub receiver deployed successfully!"

.PHONY: glr deploy-gitlab
glr deploy-gitlab:
	@if [ ! -f ./collectors/gitlabreceiver/.env ]; then \
		echo "ERROR: GitLab PAT not configured. Run 'make setup-gitlab' first."; \
		exit 1; \
	fi
	@if [ ! -s ./collectors/gitlabreceiver/.env ]; then \
		echo "ERROR: GitLab PAT file exists but is empty. Run 'make setup-gitlab' to configure it."; \
		exit 1; \
	fi
	@if ! grep -q "^GL_PAT=" ./collectors/gitlabreceiver/.env || grep -q "^GL_PAT=$$" ./collectors/gitlabreceiver/.env || grep -q "GL_PAT=YOUR_TOKEN_HERE" ./collectors/gitlabreceiver/.env; then \
		echo "ERROR: GitLab PAT is not set in .env file. Run 'make setup-gitlab' to configure it."; \
		exit 1; \
	fi
	@echo "Applying GitLab receiver configuration..."
	@export KUBECONFIG=$$HOME/.config/k3d/kubeconfig-otel-basic.yaml; \
	echo "Building kustomize resources..."; \
	if ! kustomize build ./collectors/gitlabreceiver/ > /tmp/glr-resources.yaml 2>&1; then \
		echo "ERROR: kustomize build failed. Check ./collectors/gitlabreceiver/.env file."; \
		exit 1; \
	fi; \
	echo "Applying resources..."; \
	if ! kubectl apply -f /tmp/glr-resources.yaml; then \
		echo "ERROR: kubectl apply failed. Check cluster connectivity."; \
		exit 1; \
	fi; \
	echo "GitLab receiver deployed successfully!"

.PHONY: eck-operator
eck-operator:
	kubectl apply -k ./cluster-infra/eck-operator/
	kubectl -n elastic-system rollout status --watch --timeout=30s statefulset/elastic-operator

.PHONY: eck
eck: cert-manager otel-operator eck-operator
	kubectl apply -k ./apps/eck/
	kubectl wait --for jsonpath='{.status.health}'=green -n elastic-system --timeout=30s apmserver/eck-stack-apm-server
	kubectl -n collector create secret generic eck-stack-apm-server-apm-token \
  	--from-literal secret-token="$$(kubectl -n elastic-system get secret eck-stack-apm-server-apm-token \
  	-o jsonpath="{.data.secret-token}" | base64 --decode)"
	kubectl apply -k ./collectors/gateway-eck/

.PHONY: dora
dora: default
	kubectl apply -k ./collectors/webhook/

.PHONY: ngrok
ngrok:
	helm repo add ngrok https://ngrok.github.io/kubernetes-ingress-controller
	kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml
	helm upgrade -i ngrok-ingress-controller ngrok/kubernetes-ingress-controller \
		--namespace ngrok-ingress \
		--create-namespace \
		--set credentials.apiKey="$(NGROK_AK)" \
		--set credentials.authtoken="$(NGROK_AT)"

.PHONY: tilt
tilt:
	@if [ "$(MAKECMDGOALS)" = "tilt-basic" ]; then \
			echo "Looking for otel-basic cluster..."; \
			cluster=$$(k3d cluster ls --no-headers otel-basic 2> /dev/null | awk '{print $$1}'); \
			if [[ "$$cluster" && $$cluster = "otel-basic" ]]; then \
 	  		echo "otel-basic cluster present"; \
 			else \
 	  		echo "not present... creating otel-basic cluster"; \
 	  		k3d cluster create otel-basic 1> /dev/null; \
 			fi; \
		  tilt up --file apps/Tiltfile; \
	elif [ "$(MAKECMDGOALS)" = "tilt-eck" ]; then \
			echo "Looking for otel-eck cluster..."; \
			cluster=$$(k3d cluster ls --no-headers otel-eck 2> /dev/null | awk '{print $$1}'); \
			if [[ "$$cluster" && $$cluster = "otel-eck" ]]; then \
 	  		echo "otel-eck cluster present"; \
 			else \
 	  		echo "not present... creating otel-eck cluster"; \
 	  		k3d cluster create otel-eck 1> /dev/null; \
 			fi; \
		 	tilt up --file apps/eck/Tiltfile; \
	else \
		echo "Unknown tilt option!"; \
	fi
tilt-basic: tilt
tilt-eck: tilt

.PHONY: traces
traces: cert-manager otel-operator
	kubectl apply -k ./apps/tofu-tracing-demo
	@if ! kubectl create -f https://github.com/flux-iac/tofu-controller/releases/download/v0.15.1/tf-controller.crds.yaml; then echo "Tofu Controller CRDS already installed"; fi
	kubectl apply -k ./cluster-infra/tofu-controller/

apply-traces:
	kubectl apply -k ./cluster-infra/cert-manager/
	kubectl wait --for condition=Available -n cert-manager deployment/cert-manager
	kubectl wait --for condition=Available -n cert-manager deployment/cert-manager-cainjector
	kubectl wait --for condition=Available -n cert-manager deployment/cert-manager-webhook
	@while ! kustomize build ./cluster-infra/otel-operator/ | kubectl apply -f - ; do sleep 15; done
	kubectl apply -k ./cluster-infra/rbac/
	kubectl wait --for condition=Available -n opentelemetry-operator-system deployment/opentelemetry-operator-controller-manager --timeout=120s
	@while ! kustomize build ./apps/traces | kubectl apply -f - ; do sleep 15; done
	@if ! kubectl create -f https://github.com/flux-iac/tofu-controller/releases/download/v0.15.1/tf-controller.crds.yaml; then echo "Tofu Controller CRDS already installed"; fi
	@while ! kustomize build ./cluster-infra/tofu-controller/ | kubectl apply -f - ; do sleep 10; done
	@echo "The command has been executed successfully. The Tofu Controller Traces Dashboard can be found at: http://localhost:3000"

delete-traces:
	@kubectl patch terraforms.infra.contrib.fluxcd.io demo1 -n flux-system -p '{"metadata":{"finalizers":null}}' --type=merge
	@kubectl patch terraforms.infra.contrib.fluxcd.io demo2 -n flux-system -p '{"metadata":{"finalizers":null}}' --type=merge
	@kubectl patch terraforms.infra.contrib.fluxcd.io demo3 -n flux-system -p '{"metadata":{"finalizers":null}}' --type=merge
	@kubectl patch terraforms.infra.contrib.fluxcd.io demo4 -n flux-system -p '{"metadata":{"finalizers":null}}' --type=merge
	kubectl delete -k ./cluster-infra/tofu-controller/ --ignore-not-found
	kubectl delete -k ./apps/traces --ignore-not-found
	kubectl delete -k ./cluster-infra/rbac/ --ignore-not-found
	kubectl delete -k ./cluster-infra/otel-operator/ --ignore-not-found
	kubectl delete -k ./cluster-infra/cert-manager/ --ignore-not-found
	kubectl delete -f https://github.com/flux-iac/tofu-controller/releases/download/v0.15.1/tf-controller.crds.yaml
