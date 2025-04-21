# Mac Development Environment Setup Script

This script automates the installation of essential development tools for Kubernetes-based workflows on macOS. It installs:

- **Homebrew** (Package Manager)
- **Docker Desktop** (Container Runtime)
- **k3d** (Lightweight Kubernetes Cluster Manager)
- **kubectl** (Kubernetes CLI)
- **kustomize** (Kubernetes Resource Customization)
- **Tilt** (Development Workflow Automation for Kubernetes)

## Prerequisites

- macOS with administrator privileges
- Internet connection

## Installation

1. Download the o11y-quickstart here https://github.com/liatrio/tag-o11y-quick-start-manifests/archive/refs/heads/main.zip
2. Unzip the folder in your user directory
3. Open you terminal
4. Copy `xcode-select --install` and paste it into your terminal window and hit enter
4. cd into the folder you just unzipped in your user directory
5. Run the following command - copy and paste into your terminal window and hit enter
- `chmod +x quickstart-prereq-setup.sh`
6. Run the script - copy and paste into your terminal window and hit enter
- `./quickstart-prereq-setup.sh`
7. Start Docker Desktop
8. Setup your GitHub or GitLab Receiver

#### GitHub/GitLab  Receiver Setup

To deploy the GitHub Receiver

1. Create a GitHub PAT - ./github-pat-readme.md
2. Create a file by running `touch ./collectors/githubreceiver/.env`
3. Open up the .env file you just created
4. Add `GH_PAT=<your GitHub PAT>` to the first line
5. Paste the PAT you created into the file after the GH_PAT=
6. Save teh .env file
7. Run `make ghr`

To deploy the GitLab Receiver

1. Create a GitLab PAT - ./gitlab-pat-readme.md
2. Create a file by running `touch ./collectors/gitlabreceiver/.env`
3. Open up the .env file you just created
4. Add `GH_PAT=<your GitHub PAT>` to the first line
5. Paste the PAT you created into the file after the GL_PAT=
6. Save teh .env file
7. Run `make glr`

### 9. Run Quickstart

- To deploy the basic set of configuration with OpenObserve and a Gateway
Collector, run `make`. Then login to Tilt using by navigating to
[http://localhost:10350](http://localhost:10350) in your browser.

Port forwarding is automatically enabled when running Tilt. To view Telemetry
in OpenObserve, navigate to [http://localhost:5080/](http://localhost:5080/).

Login with:

- Username: `root@example.com`
- Password: `Complexpass#123`

This corresponds with the `ZO_ROOT_USER_EMAIL` and `ZO_ROOT_USER_PASSWORD`
values that are default in the OpenObserve Statefulset.

> Note: These are default credentials, not to be used for any production
> deployment.


