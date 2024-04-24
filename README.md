# liatrio-otel-lgtm

This set of manifests deploys the [Grafana lgtm image](https://github.com/grafana/docker-otel-lgtm) with the dashboards from our [opentelemetry demo](https://github.com/liatrio/opentelemetry-demo/tree/main).  While there is a collector running in this image already, we have opted to use an external one based on the [Liatrio distribution](https://github.com/liatrio/liatrio-otel-collector).

## Installation

### Prerequisites

> You need access to a kubernetes (k8s) cluster. Here are a few options for running k8s locally:

- [Docker Desktop](https://www.docker.com/products/docker-desktop/): Local instance of Docker and k8s.
- [k3d](https://k3d.io/v5.6.3/): a lightweight wrapper to run k3s (Rancher Lab’s minimal k8s distribution) in docker.

To deploy the services with just the Engineering Effectiveness Dashboards configuration and dashboards, run:

```bash
make apply-default
```

To create those services with the addition of an instrumented Tofu Controller, run:

```bash
make apply-traces
```

> :bulb: **Tip:** After running either of those commands, you can access the Grafana dashboard at `http://localhost:3000`.

## Shutdown

To shutdown the services, run one of the following commands based on what you deployed originally:

```bash
make delete-default
```
or

```bash
make delete-traces
```

> :bulb: **Tip:** If the commands fail try re-running with `sudo`.


## Configuration
#### Dashboards
If you wish to add additional dashboards to the Grafana instance, you can do so by:
1.  Adding them to the `gateway-collector/base/grafana/provisioning/dashboards/demo` directory
2.  Update the kustomization.yml in the base configuration with the new file that will be added to the generated configmap, preferably in the one with fewer entries.
3.  Mount it inside the grafana-lgtm.yaml file like the others so it will be made available to the Grafana instance.
4.  Run `make apply-<your_configuration>` to apply the changes to the config maps which will also automatically update the grafana-lgtm deployment.

#### Tofu Controller

To be able to use the Tofu Controller after deploying the `traces` configuration, you will need to do the following.

1. Update the `source_control.yml` file in the `local-traces` overlay so that it points towards a repository with terraform resources inside of it, then in that directory run `kubectl apply -f source_control.yml` to create it.
2. Update the `terraform.yml` file so it references the name of the object you created with the `source_control.yml` file in the `sourceRef` field.  Then update the `path` field with the specific path to the terraform resources you want to use inside the repository.
3. Run `kubectl apply -f terraform.yml` to create it.
>  - For the purposes of the tracing demo these will by default be configured to apply null resources to the cluster since deploying resources to a cloud provider requires an additional auth setup that is not done here. 
>  - Deploying kubernetes resources is also possible but requires you to update the `tf-runner` service account with a cluster role that has permissions to act on those resources.
