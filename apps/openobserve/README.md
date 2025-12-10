# OpenObserve

This deployment runs [OpenObserve](https://openobserve.ai/) with automatic dashboard provisioning.

## Quick Start

```bash
# From the apps/openobserve directory
tilt up
```

OpenObserve will be available at http://localhost:5080

**Default credentials:**
- Email: `root@example.com`
- Password: `Complexpass#123`

## Dashboard Bootstrapping

OpenObserve does not natively support loading dashboards from files on startup. This deployment uses a Kubernetes Job that calls the OpenObserve API to import dashboards automatically.

### How It Works

1. The `dashboards/` folder contains exported dashboard JSON files
2. Kustomize packages these into a ConfigMap (`openobserve-dashboards`)
3. On startup, a bootstrap Job waits for OpenObserve to be healthy
4. The Job POSTs each dashboard JSON to `/api/{org}/dashboards`

### Adding or Updating Dashboards

#### Step 1: Build your dashboard locally

1. Start the local environment:
   ```bash
   tilt up
   ```

2. Open OpenObserve at http://localhost:5080 and log in

3. Create or modify dashboards using the OpenObserve UI

#### Step 2: Export the dashboard

1. Navigate to **Dashboards** in the OpenObserve UI
2. Click on the dashboard you want to export
3. Click the **⋮** (three dots) menu → **Export**
4. Save the JSON file

#### Step 3: Add to version control

1. Move the exported JSON to the `dashboards/` folder:
   ```bash
   mv ~/Downloads/MyDashboard.dashboard.json ./dashboards/my-dashboard.dashboard.json
   ```

2. Add the file to `kustomization.yaml`:
   ```yaml
   configMapGenerator:
     - name: openobserve-dashboards
       files:
         - dashboards/engineering-effectiveness.dashboard.json
         - dashboards/my-dashboard.dashboard.json  # Add your new dashboard
   ```

#### Step 4: Reload

If Tilt is running, it will automatically detect the changes and reload. Otherwise:

```bash
tilt up
```

The bootstrap Job will re-run and import all dashboards.

### File Structure

```
apps/openobserve/
├── README.md
├── Tiltfile
├── kustomization.yaml
├── sts.yaml                      # StatefulSet + Service
├── secret.yaml                   # Credentials
├── dashboard-bootstrap-job.yaml  # Import Job
└── dashboards/
    └── *.dashboard.json          # Exported dashboards
```

### Troubleshooting

**Dashboard not appearing?**

Check the bootstrap Job logs:
```bash
kubectl logs -n openobserve job/openobserve-dashboard-bootstrap
```

**Job stuck or failed?**

Delete and let Tilt recreate it:
```bash
kubectl delete job openobserve-dashboard-bootstrap -n openobserve
```

**Duplicate dashboards?**

The API creates a new dashboard each time. If you see duplicates after multiple imports, delete the extras manually in the UI. The Job has `ttlSecondsAfterFinished: 60` so completed jobs are cleaned up automatically.

## Configuration

Credentials are stored in `secret.yaml`. To change them, update the Secret and restart the StatefulSet:

```yaml
stringData:
  OO_USER: "your-email@example.com"
  OO_PASSWORD: "your-password"
  OO_ORG: "default"
```
