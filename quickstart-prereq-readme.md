# Quick Start Guide for Less Technical Users

This guide will help you set up the observability stack on macOS, even if you're not familiar with command-line tools. Follow these steps in order.

## What This Installs

This setup will install and configure:

- **Homebrew** (Package Manager for macOS)
- **Docker Desktop** (Required to run Kubernetes locally)
- **k3d** (Lightweight Kubernetes Cluster Manager)
- **kubectl** (Kubernetes command-line tool)
- **kustomize** (Kubernetes configuration tool)
- **Tilt** (Development workflow tool)
- **helm** (Kubernetes package manager)

## Prerequisites

- macOS with administrator privileges
- Internet connection
- Basic familiarity with using Terminal (we'll guide you through it)

## Step-by-Step Installation

### Step 1: Download the Project

1. Download the project from: https://github.com/liatrio/tag-o11y-quick-start-manifests/archive/refs/heads/main.zip
2. Unzip the downloaded file in your user directory (usually `/Users/YourName/`)
3. You should now have a folder called `tag-o11y-quick-start-manifests-main`

### Step 2: Install Command Line Tools (One-Time Setup)

1. Open **Terminal** (search for "Terminal" in Spotlight or find it in Applications > Utilities)
2. Copy and paste this command, then press Enter:
   ```bash
   xcode-select --install
   ```
3. A popup will appear asking to install command line tools - click **Install**
4. Wait for the installation to complete (this may take several minutes)

### Step 3: Navigate to the Project Folder

In Terminal, copy and paste these commands one at a time, pressing Enter after each:

```bash
cd ~/tag-o11y-quick-start-manifests-main
```

(If you unzipped it to a different location, adjust the path accordingly)

### Step 4: Run the Automated Setup Script

We have two setup options:

#### Option A: Automated Setup Check (Recommended)

This checks if everything is installed correctly:

```bash
make setup
```

This will:
- ✅ Check if Docker is running
- ✅ Verify all tools are installed
- ✅ Configure kubectl automatically
- ✅ Check GitHub receiver setup status

If anything is missing, it will tell you exactly what to install.

#### Option B: Install Prerequisites Script

If you need to install the prerequisites first, run:

```bash
chmod +x quickstart-prereq-setup.sh
./quickstart-prereq-setup.sh
```

This will install:
- Homebrew (if not installed)
- Docker Desktop
- k3d, kubectl, kustomize, tilt, and helm

**Note:** After running this script, you'll need to start Docker Desktop manually (see Step 5).

### Step 5: Start Docker Desktop

1. Open **Docker Desktop** from your Applications folder
2. Wait for Docker to fully start (you'll see "Docker Desktop is running" in the menu bar)
3. You can verify Docker is running by running this in Terminal:
   ```bash
   docker ps
   ```
   (If Docker isn't running, you'll get an error - just start Docker Desktop and try again)

### Step 6: Set Up GitHub or GitLab Receiver (Optional)

If you want to collect metrics from GitHub or GitLab repositories, follow these steps:

#### GitHub Receiver Setup (Easiest Method)

1. **Create a GitHub PAT** - Follow the instructions in `./github-pat-readme.md`
2. **Run the interactive setup**:
   ```bash
   make setup-github
   ```
   This will guide you through entering your GitHub PAT securely.

3. **Deploy the GitHub receiver**:
   ```bash
   make ghr
   ```

#### GitHub Receiver Setup (Manual Method)

If you prefer to set it up manually:

1. Create a GitHub PAT - Follow `./github-pat-readme.md`
2. Create the configuration file:
   ```bash
   touch ./collectors/githubreceiver/.env
   ```
3. Open the file in a text editor and add:
   ```
   GH_PAT=your_token_here
   ```
   (Replace `your_token_here` with your actual GitHub PAT)
4. Save the file
5. Deploy:
   ```bash
   make ghr
   ```

#### GitLab Receiver Setup (Easiest Method)

1. **Create a GitLab PAT** - Follow the instructions in `./gitlab-pat-readme.md`
2. **Run the interactive setup**:
   ```bash
   make setup-gitlab
   ```
   This will guide you through entering your GitLab PAT securely.

3. **Deploy the GitLab receiver**:
   ```bash
   make glr
   ```

#### GitLab Receiver Setup (Manual Method)

If you prefer to set it up manually:

1. Create a GitLab PAT - Follow `./gitlab-pat-readme.md`
2. Create the configuration file:
   ```bash
   touch ./collectors/gitlabreceiver/.env
   ```
3. Open the file in a text editor and add:
   ```
   GL_PAT=your_token_here
   ```
   (Replace `your_token_here` with your actual GitLab PAT)
4. Save the file
5. Deploy:
   ```bash
   make glr
   ```

### Step 7: Run the Quick Start

1. In Terminal, make sure you're in the project directory:
   ```bash
   cd ~/tag-o11y-quick-start-manifests-main
   ```

2. **Start the observability stack**:
   ```bash
   make
   ```

3. **Wait 2-5 minutes** for services to start. You'll see output in Terminal showing progress.

4. **Access the Tilt Dashboard** (optional):
   - Open your web browser
   - Go to: http://localhost:10350
   - This shows the status of all services

5. **Access OpenObserve** (your observability dashboard):
   - Open your web browser
   - Go to: http://localhost:5080
   - **Login with:**
     - Username: `root@example.com`
     - Password: `Complexpass#123`

> **Note:** These are default credentials for local development only. Never use these in production.

## Troubleshooting

### "Command not found" errors

- Make sure you've run `xcode-select --install` (Step 2)
- Make sure you've run the setup script (Step 4)
- Try restarting Terminal

### Docker errors

- Make sure Docker Desktop is running (check the menu bar)
- Wait a minute after starting Docker Desktop before running `make`

### "kubectl" or "k3d" errors

- Run `make setup` to check what's missing
- The setup script will tell you exactly what to install

### Need help?

- Check the main [README.md](./README.md) for more detailed instructions
- The main README has a comprehensive troubleshooting section

## What's Next?

Once everything is running:

1. Explore OpenObserve at http://localhost:5080
2. Check the Tilt dashboard at http://localhost:10350 to see service status
3. If you set up GitHub/GitLab receivers, you should see metrics appearing in OpenObserve
4. See the main README.md for advanced configuration options

## Stopping the Project

When you're done, press `Ctrl+C` in the Terminal window where `make` is running. This will stop Tilt and the services.


