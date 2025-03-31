# GitLab Metrics Collection Setup Guide

## Prerequisites

- Kubernetes cluster (k3d-otel-basic recommended)
- `kubectl` installed
- GitLab Personal Access Token
- Tilt (optional, for automated deployment)

## Environment Setup

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd tag-o11y-quick-start-manifests
   ```

2. **Configure GitLab Token**
   Create or update the `.env` file in the `collectors/gitlabreceiver/` directory:

   ```bash
   GL_PAT=your-gitlab-personal-access-token
   ```

## Deployment Options

### Option 1: Automated Deployment with Tilt

This method deploys all components together using Tilt:

```bash
export DEPLOY_GITLAB=true && export DEPLOY_LGTM=true && make tilt-basic
```

This single command will:

- Create a k3d-otel-basic cluster if it doesn't exist
- Deploy cert-manager and OpenTelemetry operator
- Deploy the GitLab receiver
- Deploy the LGTM monitoring stack
- Set up all necessary port-forwards automatically

### Option 2: Step-by-Step Deployment

If you prefer to deploy components individually:

1. **Install Certificate Manager**

   ```bash
   make cert-manager
   ```

2. **Install OpenTelemetry Operator**

   ```bash
   make otel-operator
   ```

3. **Deploy Monitoring Stack (Loki, Grafana, Tempo, Mimir)**

   ```bash
   kubectl apply -k ./apps/lgtm
   ```

4. **Deploy Gateway Collector**

   ```bash
   kubectl apply -k ./collectors/gateway/
   ```

5. **Deploy GitLab Receiver**

   ```bash
   make glr
   # or alternatively:
   kubectl apply -k ./collectors/gitlabreceiver/
   ```

## Verification

```bash
# Check if all pods are running
kubectl get pods -n collector
kubectl get pods -n monitoring
```

When using Tilt, Grafana is automatically accessible at <http://localhost:3000> (default credentials: admin/admin)

## Troubleshooting

If metrics aren't showing:

- Check collector logs: `kubectl logs -n collector deployment/otel-gitlab-collector-collector`
- Ensure GitLab token has correct permissions
- Verify network connectivity to GitLab instance
