# tag-o11y-quick-start-manifests

> [!IMPORTANT]
> Visiting here from DevOps Days Montreal? Your demo is [here](#tracing-demo)

This set of manifests gets a local observability stack up and running quickly.
It installs the following services into your local kubernetes cluster:

- [OpenObserve](https://openobserve.ai/)
- [OpenTelemetry Operator](https://opentelemetry.io/docs/kubernetes/operator/)
- [Cert Manager](https://cert-manager.io/)
- [Liatrio OpenTelemetry Collector](https://github.com/liatrio/liatrio-otel-collector)

See the [Quick Start](#quick-start) section below for step-by-step instructions.

It can optionally install the following services: (requires reading through the command options)

- Grafana
- Prometheus
- Tempo
- Loki
- OpenTelemetry Controller
- NGrok Ingress and API Gateway Controller

## Prerequisites

> **New to command-line tools?** Check out [quickstart-prereq-readme.md](./quickstart-prereq-readme.md) for a step-by-step guide designed for less technical users.

> OSX users with [Homebrew][brew] installed can install the Prerequisites by running the command `brew bundle`

1. **Docker must be running** - Ensure Docker Desktop is installed and running before proceeding. The project uses k3d which requires Docker to be active.
2. Run kubernetes locally. Here are a few options:
   1. [Docker Desktop][dd]: Local instance of Docker and k8s.
   2. [k3d][k3d]: a lightweight wrapper to run k3s (Rancher Lab's minimal k8s distribution) in docker. (Required if using tilt)
   - **Note**: The `make` command will automatically create a k3d cluster named `otel-basic` if it doesn't exist, so you don't need to create it manually.
3. Have kubectl installed
4. Have kustomize installed
5. Have [tilt][tilt] installed

### Verifying Prerequisites

Before running the project, verify your prerequisites are installed:

```bash
# Check Docker is running
docker ps

# Check required tools are installed
which k3d kubectl kustomize tilt helm

# If any are missing, install them:
brew bundle  # Installs all prerequisites from Brewfile
```

## Quick Start

### Option 1: Automated Setup (Recommended for First-Time Users)

Run the setup check to verify everything is configured correctly:

```bash
make setup
```

This will:
- ✅ Check if Docker is running
- ✅ Verify all prerequisites are installed (k3d, kubectl, kustomize, tilt, helm)
- ✅ Configure kubectl context automatically
- ✅ Check integration setup status (GitHub/GitLab - informational only)

If any checks fail, the script will tell you exactly what to fix. Integration setup is optional - you can run `make` without them.

### Option 2: Manual Setup

#### Step 1: Install Prerequisites (if not already installed)

```bash
brew bundle
```

This will install: kubectl, kustomize, helm, tilt, and k3d.

#### Step 2: Ensure Docker is Running

Make sure Docker Desktop is running before proceeding. You can verify this by running:

```bash
docker ps
```

If Docker is not running, start Docker Desktop and wait for it to fully start.

#### Step 3: Configure kubectl Context (if needed)

The `make` command now automatically configures kubectl context, but if you need to do it manually:

```bash
# Write the k3d kubeconfig
k3d kubeconfig write otel-basic

# Set KUBECONFIG to use the k3d cluster
export KUBECONFIG=$HOME/.config/k3d/kubeconfig-otel-basic.yaml

# Verify the context is set correctly
kubectl config current-context
# Should output: k3d-otel-basic
```

> **Note**: The `make` command now automatically sets the kubectl context, so you typically don't need to do this manually.

### Step 4: Run the Project

To deploy the basic set of configuration with OpenObserve and a Gateway Collector, run:

```bash
make
```

**What happens when you run `make`:**
1. ✅ Checks if Docker is running (exits with error if not)
2. ✅ Checks if a k3d cluster named `otel-basic` exists
3. ✅ If the cluster doesn't exist, automatically creates one (this may take a minute or two)
4. ✅ Automatically configures kubectl context
5. ✅ Tilt starts up and begins deploying the observability stack
6. ✅ Tilt runs in the foreground - keep the terminal window open
7. ✅ Services will start deploying - you can monitor progress in the Tilt dashboard

**Expected startup time:** Initial deployment typically takes 2-5 minutes depending on your system. The Tilt dashboard will show the status of each service as it starts up.

### Step 5: Access the Services

Once Tilt is running, you can access the services:

- **Tilt Dashboard**: Navigate to [http://localhost:10350](http://localhost:10350) in your browser to view the Tilt dashboard and monitor deployment progress
- **OpenObserve**: Navigate to [http://localhost:5080/](http://localhost:5080/) to view telemetry data

Port forwarding is automatically enabled when running Tilt. The Tilt dashboard shows the status of all services and provides easy access to logs.

### Step 6: Verify Services Are Running

You can verify that pods are running in your cluster:

```bash
# Ensure you're using the k3d context
export KUBECONFIG=$HOME/.config/k3d/kubeconfig-otel-basic.yaml

# Check all pods across all namespaces
kubectl get pods --all-namespaces

# Check pods in specific namespaces
kubectl get pods -n openobserve
kubectl get pods -n collector
kubectl get pods -n cert-manager
```

**Expected running services:**
- `openobserve-0` in the `openobserve` namespace should be `Running`
- `cert-manager-*` pods in the `cert-manager` namespace should be `Running`
- `opentelemetry-operator-controller-manager-*` in the `opentelemetry-operator-system` namespace should be `Running`

> **Note**: Some optional components (like ClickHouse/HyperDX) may show errors initially. The core observability stack (OpenObserve, cert-manager, OpenTelemetry operator) should be running for basic functionality.

Wait until core pods show `Running` status before accessing the services.

> **Note**: If you see port conflicts (e.g., port 3000 or 5080 already in use), you may need to stop other services using those ports or modify the port forwarding configuration.

**OpenObserve Login Credentials:**

- Username: `root@example.com`
- Password: `Complexpass#123`

This corresponds with the `ZO_ROOT_USER_EMAIL` and `ZO_ROOT_USER_PASSWORD`
values that are default in the OpenObserve Statefulset.

> **Note**: These are default credentials, not to be used for any production
> deployment.

### Step 7: Set Up Integrations (Optional)

After the stack is running, you can optionally add GitHub or GitLab integrations to collect repository metrics:

#### GitHub Integration

```bash
# Set up GitHub PAT interactively
make setup-github

# Deploy the GitHub receiver
make deploy-github
```

See the [GitHub Integration](#github-integration) section below for detailed instructions.

#### GitLab Integration

```bash
# Set up GitLab PAT interactively
make setup-gitlab

# Deploy the GitLab receiver
make deploy-gitlab
```

See the [GitLab Integration](#gitlab-integration) section below for detailed instructions.

**Note:** Integrations are optional. The observability stack works without them - you just won't have repository metrics.

### Step 8: Stopping the Project

To stop the project, press `Ctrl+C` in the terminal where Tilt is running. This will stop Tilt and the port forwarding, but the k3d cluster will remain running.

To delete the k3d cluster (optional cleanup):

```bash
k3d cluster delete otel-basic
```

### Troubleshooting

**Issue: Port already in use**
- Check if ports 3000, 5080, or 10350 are already in use: `lsof -i :3000 -i :5080 -i :10350`
- Stop the conflicting service or modify the port configuration

**Issue: Docker not running**
- Ensure Docker Desktop is installed and running
- Verify with `docker ps`

**Issue: k3d cluster creation fails**
- Ensure Docker has enough resources allocated (at least 2GB RAM recommended)
- Check Docker Desktop settings and increase resources if needed

**Issue: Tilt doesn't start or fails with context error**
- Verify all prerequisites are installed: `which k3d kubectl kustomize tilt`
- Check that the k3d cluster exists: `k3d cluster ls`
- Ensure kubectl context is set to `k3d-otel-basic`:
  ```bash
  k3d kubeconfig write otel-basic
  export KUBECONFIG=$HOME/.config/k3d/kubeconfig-otel-basic.yaml
  kubectl config current-context  # Should show: k3d-otel-basic
  ```
- Review Tilt logs in the terminal output

**Issue: kubectl commands hang or timeout**
- Check if kubectl is pointing to the correct cluster: `kubectl config current-context`
- If you have multiple kubeconfig files, set KUBECONFIG explicitly:
  ```bash
  export KUBECONFIG=$HOME/.config/k3d/kubeconfig-otel-basic.yaml
  ```
- Verify the k3d cluster is running: `k3d cluster ls`

**Issue: Some pods are in CrashLoopBackOff**
- Check pod logs: `kubectl logs -n <namespace> <pod-name>`
- Some optional components (like ClickHouse/HyperDX) may have configuration issues but won't affect core functionality
- Core services (OpenObserve, cert-manager, OpenTelemetry operator) should be running

Telemetry data is also sent to ClickHouse with HyperDX available for
querying and visualization of the data. HyperDX is port-forwarded to
[http://localhost:3000](http://localhost:3000). On the first login,
it will prompt to create a new user. This is just for the local
instance and can be any value for the email - e.g. `test@test.com`.

## Gateway Collector

The gateway collector is created using an  OpenTelemetry Collector distribution
that Liatrio maintains called the Liatrio OTel Collector. The gateway collector
is configured to receive, process, and export the three observability signals;
metrics, logs and traces.

In the default quick start stack, the gateway collector:

* receives metrics and processes/exports them to Prometheus.
* receives logs and processes/exports them to Loki. 
* receives traces and processes/exports them to Tempo, Jaeger.

Why do you want to use the [Gateway][gw] collector? This collector is the entry point to forwarding telemetry to the analysis backends.

[gh]: https://opentelemetry.io/docs/collector/deployment/gateway/

<hr>

**Using Tilt (Optional)**
<br>
NOTE: Requires k3d<br><br>

Tilt takes care of creating resources and giving you access to the logs, as well
as creating any port-forwarding you need. You'll have easy access from tilt's
builtin dashboard.<br>

To spin up a k3d otel-basic cluster, and deploy the default LGTM stack with
tilt; run `make tilt-basic`. <br>

To spin up a k3d otel-eck cluster, and deploy the default ECK stack with tilt;
run `make tilt-eck`. <br>

When you're done, type `ctrl-c`. <br>

Below are a couple of examples of what the tilt dashboard provides you.

![tilt table view](content/tilt_table.png)

![tilt detailed view](content/tilt_detail.png)

## GitHub Integration

The GitHub Receiver collects metrics from your GitHub repositories and sends them to your observability stack. This enables you to track DORA metrics, contributor counts, and other repository-level metrics.

### Prerequisites

- A GitHub account
- A GitHub Personal Access Token (PAT) with appropriate permissions
- The observability stack running (see [Quick Start](#quick-start))

### Step 1: Set Up GitHub Integration (Recommended)

The easiest way to configure the GitHub receiver is using the interactive setup script:

```bash
make setup-github
```

This script will:
- ✅ Guide you through creating a GitHub PAT
- ✅ Prompt you to enter your token securely (input is hidden)
- ✅ Save the token to the correct location
- ✅ Provide next steps for deployment

### Step 2: Manual GitHub Setup (Alternative)

If you prefer to set it up manually:

#### Create a GitHub Personal Access Token

1. Go to GitHub and log in to your account
2. Click your profile picture → **Settings**
3. Scroll down and click **Developer settings**
4. Click **Personal access tokens** → **Tokens (classic)**
5. Click **Generate new token** → **Generate new token (classic)**
6. Give your token a descriptive name (e.g., `Observability Stack`)
7. Set an expiration date (or choose "No expiration" for development)
8. Select the following permissions:
   - `repo` (Full control of private repositories) - Required to access repository data
   - `read:org` (Read org and team membership) - Required if scraping organization repositories
9. Click **Generate token**
10. **Copy the token immediately** - GitHub will only show it once!

For detailed instructions, see [github-pat-readme.md](./github-pat-readme.md).

#### Authorize Token for SSO Organizations (Required for Enterprise/SSO-enabled Orgs)

If you're scraping repositories from a GitHub organization that has **SSO (Single Sign-On)** enabled, you must authorize your token for that organization:

1. After generating your token, you'll see a banner or notification if SSO authorization is required
2. Alternatively, go to your **Personal access tokens** page
3. Find your newly created token
4. Click **Configure SSO** or **Authorize** next to the organization name
5. Click **Authorize** to grant the token access to the SSO-enabled organization
6. You may be redirected to your organization's SSO provider to complete authentication

> **Important**: Without SSO authorization, the GitHub receiver will not be able to access repositories in SSO-enabled organizations, even if your token has the correct permissions. You'll see authentication errors or 0 repositories found in the collector logs.

**Verifying SSO Authorization:**
- Your token should show "Authorized" or a checkmark next to the organization name
- If you see "Not authorized" or a warning icon, click it to complete the authorization

#### Configure the GitHub Receiver

1. Create the `.env` file in the GitHub receiver directory:

   ```bash
   # Create the .env file
   touch ./collectors/githubreceiver/.env
   ```

2. Add your GitHub PAT to the `.env` file:

   ```bash
   # Add your token (replace YOUR_TOKEN_HERE with your actual token)
   echo "GH_PAT=YOUR_TOKEN_HERE" > ./collectors/githubreceiver/.env
   ```

   Or manually edit the file:

   ```bash
   # Open the file in your editor
   nano ./collectors/githubreceiver/.env
   # Add this line:
   GH_PAT=ghp_your_actual_token_here
   ```

   > **Security Note**: The `.env` file is in `.gitignore` and will not be committed to git. Never commit your PAT to version control.

### Step 3: Customize Repository Selection (Optional)

By default, the GitHub receiver scrapes repositories from the `liatrio` organization. To customize which repositories are scraped:

1. Edit `./collectors/githubreceiver/colconfig.yaml`
2. Update the `github_org` field (line 18) to your GitHub organization or username:

   ```yaml
   github_org: your-org-name  # or your-username for personal repos
   ```

3. Update the `search_query` field (line 19) to customize which repositories to scrape:

   ```yaml
   search_query: org:your-org-name archived:false  # Scrape all non-archived repos
   # Or for a specific user:
   search_query: user:your-username archived:false
   # Or for repos with a specific topic:
   search_query: org:your-org-name topic:observability archived:false
   # Or for a specific repository:
   search_query: repo:your-org-name/your-repo-name
   ```

   For more search query options, see [GitHub's search syntax](https://docs.github.com/en/search-github/searching-on-github/searching-for-repositories).

4. (Optional) Update the team name (line 39) to associate metrics with your team:

   ```yaml
   - key: team.name
     value: your-team-name  # Change from "tag-o11y" to your team name
     action: upsert
   ```

5. **Apply the changes** to update the collector:

   ```bash
   # Ensure you're using the k3d context
   export KUBECONFIG=$HOME/.config/k3d/kubeconfig-otel-basic.yaml
   
   # Apply the updated configuration
   make deploy-github
   ```
   (You can also use `make ghr` - both commands do the same thing)

   This will update the OpenTelemetry Collector configuration and restart the pod with the new settings. The collector will pick up the changes within the `collection_interval` (default: 60 seconds).

### Step 4: Deploy the GitHub Receiver

With your observability stack running and the `.env` file configured:

```bash
# Ensure you're using the k3d context (usually done automatically by make)
export KUBECONFIG=$HOME/.config/k3d/kubeconfig-otel-basic.yaml

# Deploy the GitHub receiver
make deploy-github
```
(You can also use `make ghr` - both commands do the same thing)

**Note**: The `make deploy-github` command (or `make ghr`) automatically checks if your GitHub PAT is configured. If it's missing, you'll be prompted to run `make setup-github` first.

This will:
- ✅ Create a Kubernetes secret from your `.env` file
- ✅ Deploy an OpenTelemetry Collector configured to scrape GitHub
- ✅ Start collecting metrics from your specified repositories

### Step 5: Verify the GitHub Receiver is Working

1. Check that the collector pod is running:

   ```bash
   export KUBECONFIG=$HOME/.config/k3d/kubeconfig-otel-basic.yaml
   kubectl get pods -n collector | grep github
   ```

   You should see `otel-github-collector-*` pod in `Running` status.

2. Check the collector logs:

   ```bash
   # Get the pod name first
   kubectl get pods -n collector | grep github
   
   # Then view logs using the pod name (replace with your actual pod name)
   kubectl logs -n collector otel-github-collector-collector-<pod-id> --tail=50
   
   # Or view logs and filter for GitHub-related messages
   kubectl logs -n collector otel-github-collector-collector-<pod-id> | grep -i "github\|metrics\|repository"
   ```

   You should see messages like:
   - `starting the GitHub scraper` - indicates the receiver started successfully
   - `Metrics` with `vcs.repository.count` - shows metrics are being collected
   - If you see `connection refused` errors, the gateway collector may not be running yet

3. View metrics in OpenObserve:
   - Navigate to [http://localhost:5080](http://localhost:5080)
   - Log in with `root@example.com` / `Complexpass#123`
   - **Go to the "Metrics" section** (click "Metrics" in the left sidebar - bar chart icon)
   - **Query your metrics** using the query builder:
     - Search for: `vcs.repository.count` or `vcs_repository_count`
     - Or search for: `vcs.contributor.count` or `vcs_contributor_count`
     - Or search for: `organization.name="liatrio"` to see all metrics for your organization
   - **Note**: The "Streams" view may show 0 events even when data is ingested - use the "Metrics" query interface to view your data

### What Metrics Are Collected?

The GitHub receiver collects various repository metrics including:

- **Repository count** (`vcs.repository.count`) - Number of repositories found
- **Contributor counts** (`vcs.contributor.count`) - Number of contributors per repository
- **Change/Pull Request metrics** (`vcs.change.count`, `vcs.change.duration`, etc.) - PR counts and durations
- **Repository metadata** - Repository names, URLs, organization info
- **DORA metrics** (when combined with deployment events)

**Available Metrics:**
- `vcs.repository.count` - Total repositories
- `vcs.contributor.count` - Contributors per repository
- `vcs.change.count` - Pull requests (by state: open/merged)
- `vcs.change.duration` - Time PRs are open
- `vcs.change.time_to_approval` - Time to approval
- `vcs.change.time_to_merge` - Time to merge
- `vcs.ref.count` - Branch/tag counts
- `vcs.ref.lines_delta` - Lines changed
- `vcs.ref.revisions_delta` - Number of commits
- `vcs.ref.time` - Time metrics for branches

**Note**: Commit-level data (individual commits) is not collected - only aggregated metrics like commit counts (`vcs.ref.revisions_delta`) are available.

Metrics are sent to the gateway collector and then forwarded to your observability backends (OpenObserve, Prometheus, etc.).

### Understanding OpenObserve: Streams, Metrics, and Attributes

#### What are Streams?

**Streams** in OpenObserve are like "buckets" or "tables" that store your telemetry data. Each stream corresponds to a metric name (like `vcs_repository_count`). Think of streams as containers that hold data points.

- **Streams view** shows metadata about streams (names, types, sizes)
- **Metrics query interface** is where you actually query and visualize the data

#### Understanding Metrics and Attributes (Labels)

Each metric has:
- **Metric name**: e.g., `vcs.repository.count`
- **Value**: The numeric value (e.g., `1` repository)
- **Attributes/Labels**: Additional context like:
  - `vcs.repository.name` = "Liatrio-Delivery-Methodology"
  - `organization.name` = "liatrio"
  - `team.name` = "tag-o11y"
  - `vcs.change.state` = "open" or "merged"

#### How to Visualize Metrics with Repository Names

OpenObserve uses SQL-like syntax for querying metrics. Attribute names with dots may need to be quoted or accessed differently.

**Basic Query Syntax:**

1. **Simple metric query:**
   ```
   vcs_repository_count
   ```
   Note: Dots in metric names may be converted to underscores in OpenObserve.

2. **Query with filters (try these variations):**
   ```
   vcs_repository_count WHERE "vcs.repository.name" = 'Liatrio-Delivery-Methodology'
   ```
   Or:
   ```
   vcs_repository_count WHERE vcs_repository_name = 'Liatrio-Delivery-Methodology'
   ```

3. **Group by repository (SQL syntax):**
   ```
   SELECT "vcs.repository.name", SUM(vcs_change_count) 
   FROM metrics 
   GROUP BY "vcs.repository.name"
   ```
   Or try:
   ```
   SELECT vcs_repository_name, SUM(vcs_change_count) 
   FROM metrics 
   GROUP BY vcs_repository_name
   ```

**Important Notes:**
- OpenObserve may convert dots (`.`) to underscores (`_`) in field names
- Attribute names with dots may need to be quoted with double quotes: `"vcs.repository.name"`
- Try the query builder UI to see available fields and their exact names
- Use the autocomplete/suggestions in the query interface to see correct field names

**Recommended Approach:**
1. Start with a simple query: `vcs_repository_count` or `vcs_change_count`
2. Use the query builder's field selector to see available attributes
3. Build queries incrementally, checking what fields are actually available
4. Use SQL `GROUP BY` syntax for grouping, not PromQL `by` syntax

#### Example Queries (SQL-style)

- **All repositories:**
  ```sql
  SELECT * FROM vcs_repository_count
  ```

- **PR counts by repository:**
  ```sql
  SELECT "vcs.repository.name", SUM(vcs_change_count) 
  FROM metrics 
  WHERE metric_name = 'vcs.change.count'
  GROUP BY "vcs.repository.name"
  ```

- **Filter by organization:**
  ```sql
  SELECT * FROM metrics 
  WHERE "organization.name" = 'liatrio'
  ```

**Tip:** Use OpenObserve's query builder interface to explore available metrics and attributes interactively, as the exact field names may vary based on how OpenObserve stores the data.

### Troubleshooting

**Issue: Pod fails to start or shows errors**
- Verify your `.env` file exists and contains `GH_PAT=your_token`
- Check that your PAT has the correct permissions (`repo` and `read:org`)
- **If using an SSO-enabled organization**: Ensure you've authorized your token for SSO (see Step 1 above)
- Check pod logs: `kubectl logs -n collector <github-collector-pod-name>`

**Issue: No metrics appearing or 0 repositories found**
- Verify the `github_org` and `search_query` match repositories you have access to
- Check that your PAT has access to the repositories you're trying to scrape
- **If using an SSO-enabled organization**: Ensure your token is authorized for SSO (see Step 1 above). This is a common cause of 0 repositories being found.
- Test your search query on GitHub's search page to ensure it returns results
- After changing `colconfig.yaml`, remember to run `make deploy-github` (or `make ghr`) to apply the changes
- Review collector logs for authentication errors or search query issues
- Check logs to see what search query is being used: `kubectl logs -n collector <github-collector-pod-name> | grep -i "search\|query\|repository"`
- If you see authentication errors in the logs, verify your token is authorized for SSO organizations

**Issue: Rate limiting**
- GitHub API has rate limits. The collector uses a 60-second collection interval by default
- If you hit rate limits, increase the `collection_interval` in `colconfig.yaml`
- Check your rate limit status: `curl -H "Authorization: token YOUR_PAT" https://api.github.com/rate_limit`

**Issue: Timeout errors ("Client.Timeout exceeded while awaiting headers")**
- The collector may timeout when scraping large repositories or repositories with many contributors
- This is often seen in logs as: `error getting contributor count: Client.Timeout exceeded`
- These errors are non-fatal - the collector will continue and retry on the next collection interval
- If timeouts persist, consider:
  - Filtering out very large repositories from your `search_query`
  - Increasing the `collection_interval` to give more time between scrapes
  - The collector will still collect basic repository metrics even if detailed metrics timeout

**Issue: GraphQL query errors ("GraphQL query did not return the Commit Target")**
- Some repositories may have unusual commit histories that cause GraphQL query failures
- This error is typically non-fatal - the collector will skip that specific metric for that repository
- Other metrics (like repository count, contributor count) will still be collected
- If this error appears frequently, check if specific repositories are causing issues and consider excluding them from your search query

**Issue: Connection refused to gateway collector**
- If you see `connection refused` errors to `gateway-collector.collector.svc.cluster.local:4317`, the gateway collector may not be running
- Check gateway collector status: `kubectl get pods -n collector | grep gateway`
- The GitHub collector will still collect metrics (visible in debug logs) but won't forward them until the gateway collector is running
- This is expected if the gateway collector pod is in `CrashLoopBackOff` state

### Deprecated: Git Provider Receiver

The Git Provider Receiver is deprecated. Use the GitHub Receiver instead (instructions above).

## GitLab Integration

The GitLab Receiver collects metrics from your GitLab repositories and sends them to your observability stack, similar to the GitHub receiver. This enables you to track DORA metrics, contributor counts, and other repository-level metrics from GitLab.

### Prerequisites

- A GitLab account (GitLab.com or self-hosted instance)
- A GitLab Personal Access Token (PAT) with appropriate permissions
- The observability stack running (see [Quick Start](#quick-start))

### Step 1: Set Up GitLab Integration (Recommended)

The easiest way to configure the GitLab receiver is using the interactive setup script:

```bash
make setup-gitlab
```

This script will:
- ✅ Guide you through creating a GitLab PAT
- ✅ Prompt you to enter your token securely (input is hidden)
- ✅ Save the token to the correct location
- ✅ Provide next steps for deployment

### Step 2: Manual GitLab Setup (Alternative)

If you prefer to set it up manually:

#### Create a GitLab Personal Access Token

1. Go to GitLab and log in to your account
2. Click your profile picture → **Edit profile**
3. In the left sidebar, click **Access Tokens**
4. Give your token a descriptive name (e.g., `Observability Stack`)
5. Set an expiration date (optional but recommended)
6. Select the following scopes:
   - `read_api` - Required for API access
   - `read_repository` - Required to read repository data
   - `read_user` - Required to read user information
7. Click **Create personal access token**
8. **Copy the token immediately** - GitLab will only show it once!

For detailed instructions, see [gitlab-pat-readme.md](./gitlab-pat-readme.md).

#### Configure the GitLab Receiver

1. Create the `.env` file in the GitLab receiver directory:

   ```bash
   # Create the .env file
   touch ./collectors/gitlabreceiver/.env
   ```

2. Add your GitLab PAT to the `.env` file:

   ```bash
   # Add your token (replace YOUR_TOKEN_HERE with your actual token)
   echo "GL_PAT=YOUR_TOKEN_HERE" > ./collectors/gitlabreceiver/.env
   ```

   Or manually edit the file:

   ```bash
   # Open the file in your editor
   nano ./collectors/gitlabreceiver/.env
   # Add this line:
   GL_PAT=glpat_your_actual_token_here
   ```

   > **Security Note**: The `.env` file is in `.gitignore` and will not be committed to git. Never commit your PAT to version control.

### Step 3: Customize Configuration (Optional)

By default, the GitLab receiver scrapes repositories from GitLab.com. To customize:

1. Edit `./collectors/gitlabreceiver/colconfig.yaml`
2. Update the `gitlab_org` field to your GitLab organization/group name
3. Update the `endpoint` field if using a self-hosted GitLab instance:
   ```yaml
   endpoint: https://your-gitlab-instance.com/
   ```
   (Default is `https://gitlab.com/` for GitLab.com)
4. Update the `team.name` if you want to associate metrics with a specific team

### Step 4: Deploy the GitLab Receiver

With your observability stack running and the `.env` file configured:

```bash
# Ensure you're using the k3d context (usually done automatically by make)
export KUBECONFIG=$HOME/.config/k3d/kubeconfig-otel-basic.yaml

# Deploy the GitLab receiver
make deploy-gitlab
```
(You can also use `make glr` - both commands do the same thing)

**Note**: The `make deploy-gitlab` command (or `make glr`) automatically checks if your GitLab PAT is configured. If it's missing, you'll be prompted to run `make setup-gitlab` first.

This will:
- ✅ Create a Kubernetes secret from your `.env` file
- ✅ Deploy an OpenTelemetry Collector configured to scrape GitLab
- ✅ Start collecting metrics from your specified repositories

### Step 5: Verify the GitLab Receiver is Working

1. Check that the collector pod is running:

   ```bash
   kubectl get pods -n collector | grep gitlab
   ```

   You should see `otel-gitlab-collector-*` pod in `Running` status.

2. Check the collector logs:

   ```bash
   # Get the pod name first
   kubectl get pods -n collector | grep gitlab
   
   # Then view logs using the pod name
   kubectl logs -n collector otel-gitlab-collector-collector-<pod-id> --tail=50
   ```

3. View metrics in OpenObserve - GitLab metrics will appear alongside GitHub metrics, distinguished by the `vcs.vendor.name` attribute set to `gitlab`.

### Troubleshooting GitLab Receiver

**Issue: Pod fails to start or shows errors**
- Verify your `.env` file exists and contains `GL_PAT=your_token`
- Check pod logs: `kubectl logs -n collector <gitlab-pod-name>`

**Issue: No metrics appearing**
- Verify your PAT has the correct permissions (`read_api`, `read_repository`, `read_user`)
- Check that `gitlab_org` in `colconfig.yaml` matches your GitLab organization/group
- Verify the `endpoint` is correct if using self-hosted GitLab
- Check collector logs for authentication errors

**Issue: Wrong endpoint**
- If using self-hosted GitLab, update the `endpoint` field in `colconfig.yaml`
- Default is `https://gitlab.com/` for GitLab.com

### Azure DevOps Receiver

To deploy the Azure DevOps Receiver and visualize VCS, deployment, and work item metrics in Grafana:

1. **Create an Azure DevOps Personal Access Token (PAT)**
   - See [azuredevops-pat-readme.md](./azuredevops-pat-readme.md) for detailed instructions
   - Required scopes: 
     - **Code (Read)** - for VCS metrics
     - **Project and Team (Read)** - for project access
     - **Release (Read)** - for deployment metrics (optional)
     - **Work Items (Read)** - for work item metrics (optional)

2. **Configure the receiver**
   - Create a `./collectors/azuredevopsreceiver/.env` file with:
     ```bash
     # Required
     ADO_PAT=your_personal_access_token
     ADO_ORG=your_organization_name
     ADO_PROJECT=your_project_name
     ADO_SEARCH_QUERY=  # Optional: filter repos by name
     
     # Optional: Deployment metrics (leave blank to disable)
     ADO_DEPLOYMENT_PIPELINE=Your Release Pipeline Name
     ADO_DEPLOYMENT_STAGE=Production
     ADO_DEPLOYMENT_LOOKBACK_DAYS=30
     
     # Optional: Work item metrics (leave blank to disable)
     # Note: work_item_types is configured in colconfig.yaml
     ADO_WORK_ITEM_LOOKBACK_DAYS=30
     ```

3. **Deploy with ADO receiver and Grafana**
   ```bash
   DEPLOY_ADO=true DEPLOY_LGTM=true make
   ```

4. **Access the dashboards**
   - Navigate to [http://localhost:3001](http://localhost:3001)
   - **VCS Metrics:** **Dashboards** → **DORA** → **DORA VCS Metrics - Azure DevOps**
   - **Deployment Metrics:** **Dashboards** → **DORA** → **DORA Deployment Metrics - Azure DevOps**
   - **Work Item Metrics:** **Dashboards** → **DORA** → **Azure DevOps Work Items**

For detailed setup and troubleshooting, see:
- [azuredevops-dashboard-readme.md](./azuredevops-dashboard-readme.md) - Complete dashboard guide
- [azuredevops-pat-readme.md](./azuredevops-pat-readme.md) - PAT setup and permissions

## DORA

> **Note**: DORA functionality requires additional prerequisites (Helm and NGrok) that are not needed for basic observability. If you're only using the observability stack without DORA metrics, you can skip this section.

### DORA Prerequisites

The DORA Collector requires the following additional prerequisites beyond the basic observability stack:

1. **Helm** - Required for deploying the NGrok ingress controller
2. **NGrok Account** - Free account with a permanent domain (required for webhook routing)
3. **NGrok API Key and Auth Token** - Obtained from your NGrok dashboard

The DORA Collector leverages the WebHook Events OpenTelemetry Receiver. As
events occur (like deployments) the event LogRecords are sent to the collector.
In order to enable sending of data from locations like GitHub, you have to be
able to route to your local installation of this collector. In this repository
we've defaulted to leveraging NGrok for this configuration. As such this
presumes that you have a free NGrok account, an API Key, and an AuthToken.

1. From the [NGrok dashboard][ngrok-dash] get your [API Key][ngrok-api] from NGrok.
2. Get your [Auth Token][ngrok-api] from NGrok.
3. Get your [free permanent domain][ngrok-domain] from NGrok.
4. Export your env vars:

   ```bash
   export NGROK_AUTHTOKEN=authtoken
   export NGROK_API_KEY=apikey
   ```

5. Run `make ngrok` to setup the controller.
6. Update the [webhook route config](./collectors/webhook/ngrok-route.yaml)
   with your permanent domain in the host rules (see example below):

   ```yaml
   spec:
   ingressClassName: ngrok
   rules:
     # Change this to match your NGrok permanent domain
     - host: example.ngrok-free.app
   ```

7. Run `make dora`

<!-- TODO: Add instructions for GitLab -->

## Tracing Demo

![Logo](content/logo3.png)

1. To run the demo, you will need to have a Kubernetes cluster running locally
   as well as `kubectl` installed. We will use [k3d](https://k3d.io/) to create
   a local cluster. If you do not have these installed, you can install them by
   running one of the followings commands depending on your OS:

   **Linux**

   ```bash
   curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   ```

   **Mac**

   ```bash
   brew install k3d
   brew install kubectl
   ```

2. Once we have these prerequisites installed, we can actually deploy the local
   cluster by running the following command:

   ```bash
   k3d cluster create mycluster
   ```

3. Once the cluster is created, we can actually deploy the demo resources
   themselves by running:

   ```bash
   make apply-traces
   ```

4. Verify that the namespaces are present and the pods are running. They should
   look like this:

   ![kubectl get namespaces](content/namespaces.png)
   ![kubectl get pods --all-namespaces](content/all_pods.png)

5. Once everything is up and looking healthy, we can portforward the Grafana
   service to view the dashboard by doing the following:
   ![kubectl port-forward svc/grafana -n grafana 3000:3000](content/portforwarding.png)

6. Once the port-forward is setup, you can visit the Grafana dashboard by
   visiting `http://localhost:3000` in your browser. The dashboard will be the
   only one in the demo folder and will look like this:
   ![Grafana Dashboard](content/dashboard.png)

   > [!IMPORTANT] Grafana will ask for a login which will just be the default
   > credentials of `username:admin password:admin`. It will ask you to change
   > it but you can skip this step if you would like.

### Cleanup

```bash
make delete-traces
```

## Tracing

We have an instrumented version of the flux-iac Tofu Controller which is part of
what makes this demo possible. Our fork with the changes are
[here][tofu-controller]

The other core piece of the demo is our instrumented version of the OpenTofu
binary. Similarly our fork with the changes are
[here][open-tofu]

## Configuration

To be able to use the Tofu Controller after deploying the `traces`
configuration with your own terraform, you will need to do the following.

1. Update the `source_control.yml` file in the `cluster-infra/tofu-controller/` folder so that
   it points towards a repository with terraform resources inside of it.
   ![Source](content/source.png)

2. Update one of the `terraform.yml` files in the same folder so it references the name of the object you
   created with the `source_control.yml` file in the `sourceRef` field. Then
   update the `path` field with the specific path to the terraform resources
   you want to use inside the repository.
   ![Source](content/terraform.png)

3. If you add your own files to the folder, you will need to update the
   `kustomization.yml` file in the folder to include the new files if you want
   them to be deployed with the rest of the resources

4. Run `make apply-traces` to update the resources in the cluster with the new
   configuration.

> - For the purposes of the tracing demo these will by default be configured
>   to apply null resources to the cluster since deploying resources to a
>   cloud provider requires an additional auth setup that is not done here.
> - Deploying kubernetes resources is also possible but requires you to update
>   the `tf-runner` service account with a cluster role that has permissions to
>   act on those resources.

[brew]: https://brew.sh/
[dd]: https://www.docker.com/products/docker-desktop/
[k3d]: https://k3d.io/v5.6.3/
[ngrok-api]: https://dashboard.ngrok.com/api
[ngrok-dash]: https://dashboard.ngrok.com/
[ngrok-domain]: https://dashboard.ngrok.com/cloud-edge/domains
[tofu-controller]: https://github.com/liatrio/tofu-controller/tree/tracing
[open-tofu]: https://github.com/liatrio/opentofu/tree/tracing
[tilt]: https://tilt.dev
