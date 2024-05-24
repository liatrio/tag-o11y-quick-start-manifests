# tag-o11y-quick-start-manifests

> [!NOTE]
> Visiting here from DevOps Days Montreal? Your demo is [here](#tracing-demo)

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

> OSX users with [Homebrew](https://brew.sh/) installed can install the Prerequisites by running the command `brew bundle`

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
   
---

<!-- TODO: Add instructions for GitLab -->

<img src="content/logo3.png" alt="logo" width="9000">

# Tracing Demo
## Getting Started

1. To run the demo, you will need to have a Kubernetes cluster running locally as well as `kubectl` installed.  We will use [k3d](https://k3d.io/) to create a local cluster.  If you do not have these installed, you can install them by running one of the followings commands depending on your OS:

Linux
```bash
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
```
Mac
```bash
brew install k3d
brew install kubectl
```

2. Once we have these prerequisites installed, we can actually deploy the local cluster by running the following command:
```bash
k3d cluster create mycluster
```

3. Once the cluster is created, we can actually deploy the demo resources themselves by running:
```bash
make apply-traces
```

4. Verify that the namespaces are present and the pods are running.  They should look like this:
![image](content/namespaces.png)
![image](content/all_pods.png)

5. Once everything is up and looking healthy, we can portforward the Grafana service to view the dashboard by doing the following:
![image](content/portforwarding.png)

6. Once the portforwarding is setup, you can visit the Grafana dashboard by visiting `http://localhost:3000` in your browser. The dashboard will be the only one in the demo folder and will look like this:
![image](content/dashboard.png)
> [!IMPORTANT]
> Grafana will ask for a login which will just be the default credentials of `username:admin password:admin`. It will ask you to change it but you can skip this step if you would like.


### Cleanup

```bash
make delete-traces
```

## Configuration

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
