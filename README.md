# tag-o11y-quick-start-manifests

This set of manifests gets a local obersvability stack up and running quickly.
It installs the following services into your local kubernetes cluster:

* Grafana
* Prometheus
* Tempo
* Loki
* Certificate Manager
* OpenTelemetry Controller
* Liatrio OpenTelemetry Collector
* NGrok Ingress and API Gateway Controller

# Getting Started

## Prerequisites

1. Run kubernetes locally. Here are a few options:
- [Docker Desktop](https://www.docker.com/products/docker-desktop/): Local
  instance of Docker and k8s.
- [k3d](https://k3d.io/v5.6.3/): a lightweight wrapper to run k3s (Rancher
  Lab’s minimal k8s distribution) in docker.
2. Have kubectl installed
3. Have kustomize installed
4. If using DORA, have NGROK configured with a domain and update the
   configuration accordingly.
5. Have a free NGrok Account with a Permanent domain (if wanting to deploy DORA)
6. Have helm installed (gross, only for the ngrok helm chart, will remove this eventually)

## Deploy

### Quick Start

To deploy the basic set of configuration with the LGTM stack and a Gateway
OpenTelemetry Collector, run:

```bash
make
```

### Git Provider Receiver (GitHub)

To deploy the GitProvider Receiver:

> Make sure the [Quick Start](#quick-start) has been run first.

1. Create a GitHub PAT
2. Create a `.env` file at the root containing the PAT **Nothing Else Aside from the PAT**
3. Create a kubernetes secret with that PAT by running

```bash
kubectl create secret generic github-pat --from-file=GH_PAT=./.env \
--namespace collector
```
4. Run `make gpr`

### Git Provider Receiver (GitLab)

<!-- TODO: Add instructions for GitLab -->

### DORA 

The DORA Collector leverages the WebHook Events OpenTelemetry Receiver. As
events occur (like deployments) the event LogRecords are sent to the collector.
In order to enable sending of data from locations like GitHub, you have to be
able to route to your local installation of this collector. In this repository
we've defaulted to leveraging NGrok for this configuration. As such this
presumes that you have a free NGrok account, an API Key, and an AuthToken.

1. From the [NGrok dashboard](https://dashboard.ngrok.com/) get your [API Key](https://dashboard.ngrok.com/api) from NGrok.
2. Get your [Auth Token](https://dashboard.ngrok.com/api) from NGrok.
3. Get your [free permanent domain](https://dashboard.ngrok.com/cloud-edge/domains) from NGrok.
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
<!-- TODO: Add explanation for what and why -->

1. Run `make traces` to deploy the tracing demo


--- 

<!-- TODO: Edit this as it's now deprecated -->

## Destroy

> You need access to a kubernetes (k8s) cluster. Here are a few options for
> running k8s locally:


To deploy the Grafana LGTM stack with no dashboards or other configurations,
run:

```bash
make apply-basic
```


To deploy the services with just the Engineering Effectiveness Dashboards
configuration and dashboards, run:

```bash
make apply-default
```

To create the services with the addition of an instrumented Tofu Controller,
run:

```bash
make apply-traces
```

> :bulb: **Tip:** After running either of those commands, you can access the
> Grafana dashboard at `http://localhost:3000`.

## Shutdown

To shutdown the services, run one of the following commands based on what you
deployed originally:

```bash
make delete-basic
```

```bash
make delete-default
```

```bash
make delete-traces
```

> :bulb: **Tip:** If the commands fail try re-running with `sudo`.


<!-- TODO: Edit this as it's now deprecated -->

## Configuration

#### Dashboards
If you wish to add additional dashboards to the Grafana instance, you can do so
by:

1.  Adding them to the
    `gateway-collector/overlays/<your_configuration>/grafana/provisioning/dashboards/demo`
    directory
2.  Update the kustomization.yml in your configuration with the new file that
    will be added to the generated configmap
3.  Mount it inside the grafana-lgtm.yaml file like the others so it will be
    made available to the Grafana instance.
4.  Run `make apply-<your_configuration>` to apply the changes to the config
    maps which will also automatically update the grafana-lgtm deployment.

#### Tofu Controller

To be able to use the Tofu Controller after deploying the `traces`
configuration with your own terraform, you will need to do the following.

1. Update the `source_control.yml` file in the `local-traces` overlay so that
   it points towards a repository with terraform resources inside of it.
2. Update the `terraform.yml` file so it references the name of the object you
   created with the `source_control.yml` file in the `sourceRef` field.  Then
   update the `path` field with the specific path to the terraform resources
   you want to use inside the repository.
3. Run `make deploy-traces` to update the resources in the cluster with the new
configuration.

>  - For the purposes of the tracing demo these will by default be configured
>    to apply null resources to the cluster since deploying resources to a
>    cloud provider requires an additional auth setup that is not done here. 
>  - Deploying kubernetes resources is also possible but requires you to update
>  the `tf-runner` service account with a cluster role that has permissions to
>  act on those resources.
