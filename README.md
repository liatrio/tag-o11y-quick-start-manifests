# liatrio-otel-lgtm

This set of manifests deploys the [Grafana lgtm image](https://github.com/grafana/docker-otel-lgtm) with the dashboards from our [opentelemetry demo](https://github.com/liatrio/opentelemetry-demo/tree/main).  While there is a collector running in this image already, we have opted to use an external one based on the [Liatrio distribution](https://github.com/liatrio/liatrio-otel-collector).

## Installation

After you have a cluster created, run the following command:

```bash
make apply-all
```