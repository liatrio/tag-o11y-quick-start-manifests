# Azure DevOps Grafana Dashboard Setup

This guide explains how to use the Azure DevOps VCS metrics dashboard with your observability stack.

---

## Overview

The Azure DevOps dashboard (`vcs-trunk-based-development-ado.json`) provides visualization of VCS metrics collected from Azure DevOps repositories, including:

- **Branch Metrics**: Branch count, age, and distribution
- **Pull Request Metrics**: Open PR duration and merged PR age
- **Repository Metrics**: Repository and contributor counts
- **Trunk-Based Development Indicators**: Average branch age and count

---

## Differences from GitHub Dashboard

The ADO dashboard differs from the GitHub dashboard in several ways:

| Feature | GitHub Dashboard | ADO Dashboard |
|---------|------------------|---------------|
| Organization filter | ✅ Yes | ❌ No (ADO doesn't expose this) |
| Metric suffix | `_seconds` | No suffix |
| PR count metrics | ✅ Yes | ❌ Not implemented yet |
| Approval time metrics | ✅ Yes | ❌ Not implemented yet |
| Security/CVE metrics | ✅ Yes | ❌ Not available |
| Label names | `repository_name` | `vcs_repository_name` |

---

## Prerequisites

1. **Azure DevOps Receiver** configured and running
   - See [azuredevops-pat-readme.md](./azuredevops-pat-readme.md) for PAT setup
   - Collector must be deployed with ADO receiver enabled

2. **OpenObserve** (or Prometheus) as metrics backend
   - Dashboard is configured to use OpenObserve by default
   - Can be switched to Prometheus if needed

3. **Grafana** deployed with dashboard provisioning
   - LGTM stack must be enabled: `DEPLOY_LGTM=true make`

---

## Setup Instructions

### 1. Configure Azure DevOps Receiver

Create `.env` file in `collectors/azuredevopsreceiver/`:

```bash
ADO_PAT=your_personal_access_token
ADO_ORG=your_organization_name
ADO_PROJECT=your_project_name
ADO_SEARCH_QUERY=  # Optional: filter repos (e.g., "service")
```

### 2. Deploy with Tilt

```bash
# Enable ADO receiver and LGTM stack
DEPLOY_ADO=true DEPLOY_LGTM=true make
```

### 3. Access Grafana

1. Navigate to [http://localhost:3001](http://localhost:3001)
2. Login with default credentials (check Grafana docs)
3. Go to **Dashboards** → **DORA** → **DORA VCS Metrics - Azure DevOps**

### 4. Configure Dashboard Variables

The dashboard has two variables:

- **team**: Filter by team name (from `team.name` resource attribute)
- **repo**: Filter by repository name

Both support multi-select and "All" option.

---

## Available Metrics

### Implemented Metrics

| Metric | Description | Type |
|--------|-------------|------|
| `vcs_repository_count` | Number of repositories | Gauge |
| `vcs_contributor_count` | Number of contributors per repo | Gauge |
| `vcs_ref_count` | Number of branches/refs per repo | Gauge |
| `vcs_ref_time` | Age of branches in seconds | Gauge |
| `vcs_change_duration` | Duration of open PRs in seconds | Gauge |
| `vcs_change_time_to_merge` | Time to merge completed PRs | Histogram |

### Not Yet Implemented

| Metric | Status | Notes |
|--------|--------|-------|
| `vcs_change_count` | ❌ Not implemented | PR counts by state |
| `vcs_change_time_to_approval` | ❌ Not implemented | Requires approval timestamp from API |
| `vcs_cve_count` | ❌ Not available | Security metrics not provided by ADO receiver |

---

## Dashboard Panels

### Histogram Panels (Top)
- **Branch Time Buckets**: Distribution of branch ages
- **Pull Request Open Time Buckets**: Distribution of PR durations

### Trunk-Based Development Section
- **Average Branch Age (Days)**: Stat panel showing average across all repos
- **Average Open Branches**: Number of branches per repo
- **Average Open Pull Request Duration (Days)**: Average time PRs stay open
- **Open Branches**: Time series of branch counts
- **Open Pull Request Age**: Time series of PR durations

### Detailed VCS Metrics Section
- **Repo Count**: Total number of repositories
- **Average Branch Count**: Branches per repository
- **Average Open Pull Request Count**: Open PRs per repository
- **Average Branch Age Per Repo In Days**: Gauge showing per-repo averages
- **Contributor Count**: Contributors per repository
- **Branch Count**: Branches per repository (excluding main)
- **Branch Age**: Age of all branches
- **Open Pull Request Count**: Number of open PRs
- **Open Pull Request Age**: Age of open PRs
- **Merged Pull Request Age**: Time to merge for completed PRs

---

## Troubleshooting

### Dashboard Shows "No Data"

1. **Check ADO receiver is running**:
   ```bash
   kubectl get pods -n collector | grep azuredevops
   ```

2. **Verify metrics are being collected**:
   ```bash
   kubectl logs -n collector deployment/otel-azuredevops-collector
   ```

3. **Query OpenObserve directly**:
   - Navigate to [http://localhost:5080](http://localhost:5080)
   - Go to Logs → Metrics
   - Search for `vcs_repository_count`

4. **Check Grafana datasource**:
   - Go to **Configuration** → **Data Sources**
   - Verify **OpenObserve** is configured and working
   - Test the connection

### "Organization" Variable Appears

If you see an "organization" dropdown, the dashboard wasn't updated correctly. The ADO dashboard should only have "team" and "repo" variables.

### Panels Show Wrong Data

Verify the dashboard is using the correct datasource:
- Should be `openobserve-metrics` (UID)
- Not `${DS_PROMETHEUS}` or `webstore-metrics`

---

## Customization

### Change Data Source

To use Prometheus instead of OpenObserve:

1. Update `apps/lgtm/grafana/datasources.yaml`
2. Change `isDefault: true` from OpenObserve to Prometheus
3. Restart Grafana

### Adjust Time Ranges

Default time range is "Last 3 hours". To change:
1. Click time picker in top-right
2. Select desired range
3. Save dashboard to persist

### Add Custom Panels

The dashboard JSON can be edited to add custom visualizations:
1. Edit in Grafana UI
2. Export JSON
3. Update `apps/lgtm/grafana/dashboards/dora/vcs-trunk-based-development-ado.json`

---

## Contributing

When contributing dashboard changes:

1. **Test thoroughly** with real ADO data
2. **Document any new variables** or configuration
3. **Update this README** with new features
4. **Ensure backwards compatibility** where possible
5. **Follow existing naming conventions**

---

## Additional Resources

- [Azure DevOps Receiver Documentation](https://github.com/liatrio/liatrio-otel-collector/tree/main/receiver/azuredevopsreceiver)
- [OpenTelemetry Semantic Conventions for VCS](https://opentelemetry.io/docs/specs/semconv/vcs/)
- [Grafana Dashboard Best Practices](https://grafana.com/docs/grafana/latest/dashboards/build-dashboards/best-practices/)
