# Self-Hosted Runner Setup Guide

This guide explains how to set up a self-hosted GitHub Actions runner for deploying your Node.js application.

## Prerequisites

- A Linux/macOS/Windows machine with internet access
- Node.js 18.x or 20.x installed
- Git installed
- Sudo/Administrator privileges

## Step 1: Create Self-Hosted Runner

### 1.1 Navigate to Repository Settings

1. Go to your GitHub repository
2. Click on **Settings** tab
3. In the left sidebar, click **Actions** → **Runners**
4. Click **New self-hosted runner**

### 1.2 Choose Runner Configuration

- **Operating System**: Select your server's OS (Linux/macOS/Windows)
- **Architecture**: Select appropriate architecture (x64/ARM64)

### 1.3 Download and Configure Runner

Follow the commands provided by GitHub (example for Linux x64):

```bash
# Create a folder
mkdir actions-runner && cd actions-runner

# Download the latest runner package
curl -o actions-runner-linux-x64-2.311.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz

# Extract the installer
tar xzf ./actions-runner-linux-x64-2.311.0.tar.gz

# Create the runner and start the configuration experience
./config.sh --url https://github.com/YOUR_USERNAME/YOUR_REPO --token YOUR_TOKEN
```

### 1.4 Configure Runner

When prompted, provide:

- **Runner name**: `production-server` (or your preferred name)
- **Runner group**: `default`
- **Labels**: `self-hosted,linux,x64,production` (add custom labels as needed)
- **Work folder**: Press Enter for default

## Step 2: Install Required Dependencies

### 2.1 Install Node.js and npm

```bash
# For Ubuntu/Debian
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# For CentOS/RHEL
curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
sudo yum install -y nodejs

# For macOS
brew install node@20
```

### 2.2 Install PM2 (Process Manager)

```bash
sudo npm install -g pm2
```

### 2.3 Create Deployment Directory

```bash
sudo mkdir -p /opt/node-apps
sudo chown $USER:$USER /opt/node-apps
```

### 2.4 Install Additional Tools

```bash
# Install curl if not present
sudo apt-get install curl  # Ubuntu/Debian
sudo yum install curl      # CentOS/RHEL

# Install lsof for port checking
sudo apt-get install lsof  # Ubuntu/Debian
sudo yum install lsof      # CentOS/RHEL
```

## Step 3: Start the Runner

### 3.1 Start Runner Manually (for testing)

```bash
cd actions-runner
./run.sh
```

### 3.2 Install Runner as Service (recommended for production)

```bash
cd actions-runner
sudo ./svc.sh install
sudo ./svc.sh start
```

### 3.3 Check Runner Status

```bash
sudo ./svc.sh status
```

## Step 4: Configure Firewall (if applicable)

### 4.1 Allow Port 3000 (application port)

```bash
# Ubuntu/Debian (ufw)
sudo ufw allow 3000

# CentOS/RHEL (firewalld)
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --reload

# iptables
sudo iptables -A INPUT -p tcp --dport 3000 -j ACCEPT
```

## Step 5: Runner Labels and Configuration

### 5.1 Custom Labels

You can add custom labels during configuration or modify them later:

- `production`: For production deployments
- `staging`: For staging deployments
- `nodejs`: For Node.js applications
- `web-server`: For web applications

### 5.2 Environment Variables

Set environment variables on the runner machine:

```bash
# Add to ~/.bashrc or ~/.profile
export NODE_ENV=production
export PORT=3000
```

## Step 6: Security Considerations

### 6.1 User Permissions

- Create a dedicated user for the runner
- Limit sudo permissions to specific commands
- Use proper file permissions

### 6.2 Network Security

- Use firewall rules to restrict access
- Consider using reverse proxy (nginx/apache)
- Enable HTTPS in production

### 6.3 Runner Security

```bash
# Create dedicated runner user
sudo useradd -m -s /bin/bash github-runner
sudo usermod -aG sudo github-runner

# Set up runner under this user
sudo su - github-runner
```

## Step 7: Monitoring and Maintenance

### 7.1 Monitor Runner Status

```bash
# Check if runner service is running
sudo systemctl status actions.runner.*

# View runner logs
sudo journalctl -u actions.runner.* -f
```

### 7.2 Monitor Application

```bash
# PM2 monitoring
pm2 status
pm2 logs
pm2 monit

# System monitoring
htop
df -h
free -m
```

### 7.3 Maintenance Tasks

```bash
# Update runner (when new version available)
cd actions-runner
sudo ./svc.sh stop
# Download and extract new version
sudo ./svc.sh start

# Clean up old deployments
find /opt/node-apps -type d -mtime +30 -exec rm -rf {} \;

# PM2 maintenance
pm2 update
pm2 save
```

## Step 8: Troubleshooting

### 8.1 Common Issues

**Runner not appearing in GitHub:**

- Check internet connectivity
- Verify token is valid
- Check runner service status

**Deployment fails:**

- Check file permissions
- Verify Node.js version
- Check available disk space
- Review PM2 logs

**Application not accessible:**

- Check if port 3000 is open
- Verify application is running (`pm2 status`)
- Check firewall settings

### 8.2 Useful Commands

```bash
# Restart runner service
sudo systemctl restart actions.runner.*

# Check runner logs
tail -f /home/github-runner/actions-runner/_diag/Runner_*.log

# Check application logs
pm2 logs node-express-app

# Check system resources
df -h && free -m && ps aux --sort=-%cpu | head
```

## Step 9: Workflow Integration

The workflow file (`deploy.yml`) is configured to:

- Run on `self-hosted` runners
- Use labels for targeting specific runners
- Handle deployment to `/opt/node-apps/` directory
- Use PM2 for process management
- Perform health checks after deployment

### 9.1 Runner Labels in Workflow

```yaml
runs-on: self-hosted  # Uses any self-hosted runner
# or
runs-on: [self-hosted, linux, production]  # Uses specific labeled runner
```

## Step 10: Production Recommendations

1. **Use HTTPS**: Set up SSL certificates
2. **Reverse Proxy**: Use nginx/apache for better security
3. **Monitoring**: Set up application monitoring (e.g., New Relic, DataDog)
4. **Backups**: Regular backup of application and data
5. **Updates**: Keep runner and dependencies updated
6. **Logging**: Centralized logging solution
7. **Alerts**: Set up alerts for deployment failures

---

## Quick Setup Script

For quick setup, you can use this script:

```bash
#!/bin/bash
# quick-setup.sh

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install PM2
sudo npm install -g pm2

# Create deployment directory
sudo mkdir -p /opt/node-apps
sudo chown $USER:$USER /opt/node-apps

# Install additional tools
sudo apt-get update
sudo apt-get install -y curl lsof

echo "✅ Self-hosted runner environment setup complete!"
echo "Next steps:"
echo "1. Configure GitHub Actions runner"
echo "2. Start the runner service"
echo "3. Test deployment"
```

Save this as `quick-setup.sh`, make it executable (`chmod +x quick-setup.sh`), and run it on your server.
