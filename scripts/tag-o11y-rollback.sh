#!/bin/bash

# Prompt the user to ensure they want to rollback
read -p "Are you sure you want to rollback the setup? (Y/N): " response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
  echo "Rollback aborted."
  exit 1
fi

# Stop port forwarding
echo "Stopping port forwarding..."
pkill -f "kubectl port-forward svc/gateway-collector -n collector 4317:4317"
pkill -f "kubectl port-forward svc/jaeger-all-in-one-query -n jaeger 16686:16686"
pkill -f "kubectl port-forward svc/grafana -n grafana 3001:3000"

# Function to delete resources and wait for their deletion
delete_and_wait() {
  kubectl delete -k $1 --ignore-not-found
  kubectl wait --for=delete -k $1 --timeout=120s
}

# Delete resources in reverse order of their creation
delete_and_wait ./apps/default
delete_and_wait ./collectors/gateway/
delete_and_wait ./cluster-infra/rbac/
delete_and_wait ./cluster-infra/otel-operator/
delete_and_wait ./cluster-infra/jaeger-operator/
delete_and_wait ./cluster-infra/cert-manager/

# Delete specific deployments and wait for their deletion
kubectl delete deployment opentelemetry-operator-controller-manager -n opentelemetry-operator-system --ignore-not-found
kubectl delete deployment jaeger-operator -n observability --ignore-not-found
kubectl delete deployment cert-manager -n cert-manager --ignore-not-found
kubectl delete deployment cert-manager-cainjector -n cert-manager --ignore-not-found
kubectl delete deployment cert-manager-webhook -n cert-manager --ignore-not-found

# Print URLs for confirmation
echo "Resources have been deleted. Please verify the following URLs are no longer accessible:"
echo "Grafana: http://localhost:3000"
echo "Loki: http://localhost:3100"
echo "Tempo: http://localhost:4317"
echo "Prometheus: http://localhost:9090"
echo "Jaeger: http://localhost:16686"

# Uninstall k3d and kubectl if necessary
# echo "Uninstalling k3d and kubectl..."
# brew uninstall k3d
# brew uninstall kubectl

echo "Rollback completed."