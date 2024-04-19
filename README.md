# liatrio-otel-lgtm

This set of manifests deploys the [Grafana lgtm image](https://github.com/grafana/docker-otel-lgtm) with the dashboards from our [opentelemetry demo](https://github.com/liatrio/opentelemetry-demo/tree/main).  While there is a collector running in this image already, we have opted to use an external one based on the [Liatrio distribution](https://github.com/liatrio/liatrio-otel-collector).

## Installation

### Prerequisites

> You need access to a kubernetes (k8s) cluster. Here are a few options for running k8s locally:

- [Docker Desktop](https://www.docker.com/products/docker-desktop/): Local instance of Docker and k8s.
- [k3d](https://k3d.io/v5.6.3/): a lightweight wrapper to run k3s (Rancher Lab’s minimal k8s distribution) in docker.

After you have a cluster created, run the following command to deploy the services:

```bash
make apply-all
```

> :bulb: **Tip:** After running `make apply-all`, you can access the Grafana dashboard at `http://localhost:3000`.

## Shutdown

To shutdown the services, run the following command:

```bash
make delete-all
```

> :bulb: **Tip:** If the commands fail try re-running with `sudo`.
