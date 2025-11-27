# 🐳 Docker Claude Code

> **Professional Docker container for [Claude Code](https://github.com/anthropic-ai/claude-code) - The AI coding assistant that revolutionizes development productivity**

[![Docker Image Size](https://img.shields.io/docker/image-size/user/claude-code/latest)](https://hub.docker.com/r/user/claude-code)
[![GitHub](https://img.shields.io/github/license/legido-ai-workspace/docker-claude-code)](LICENSE)
[![Docker Pulls](https://img.shields.io/docker/pulls/user/claude-code)](https://hub.docker.com/r/user/claude-code)

Claude Code is an advanced AI coding assistant designed to enhance developer productivity through intelligent code generation, completion, and analysis. This Docker image provides a **secure**, **isolated**, and **production-ready** environment to run Claude Code with all necessary dependencies pre-configured.

## 📑 Table of Contents

- [✨ Key Features](#-key-features)
- [🚀 Quick Start](#-quick-start)
  - [Prerequisites](#prerequisites)
  - [⚡ One-Command Setup](#-one-command-setup)
- [⚙️ Advanced Configuration](#️-advanced-configuration)
- [🚀 Deployment Options](#-deployment-options)
  - [Option 1: 📦 Pre-built Image (Recommended)](#option-1--pre-built-image-recommended)
  - [Option 2: 🔨 Custom Build (Advanced Users)](#option-2--custom-build-advanced-users)
- [💡 Usage Examples](#-usage-examples)
- [🔌 MCP Server Configuration](#-mcp-server-configuration)
- [🔄 Maintenance & Updates](#-maintenance--updates)
- [📂 Volume Management](#-volume-management)
- [🛡️ Security Features](#️-security-features)
- [🔧 Troubleshooting](#-troubleshooting)
- [📄 License](#-license)

## ✨ Key Features

| Feature | Description | Benefit |
|---------|-------------|---------|
| 🏗️ **Multi-stage Build** | Optimized Docker image with separated build/runtime environments | Reduced image size (~60% smaller) |
| 🐋 **Docker-in-Docker** | Full Docker CLI support with socket mounting | Complete containerization workflow |
| 📁 **Volume Management** | Smart volume mounting for projects and configuration | Persistent data and easy file access |
| 🔍 **Health Monitoring** | Built-in container health checks | Reliable production deployment |
| ⚡ **Performance** | Cached layers and optimized dependencies | Fast builds and quick startup |
| 🛡️ **Security** | Non-root execution with minimal privileges | Enhanced container security |

## 🚀 Quick Start

### Prerequisites

| Requirement | Version | Purpose |
|-------------|---------|---------|
| 🐳 **Docker** | 20.10+ | Container runtime |
| 🔧 **Docker Compose** | 2.0+ | Multi-container orchestration |
| 💾 **Free Disk Space** | 2GB+ | Image and container storage |

### ⚡ One-Command Setup

```bash
# Pull and run the latest image
docker run -it --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $HOME/.claude:/home/node \
  -v $PWD:/projects \
  --name claude-code \
  ghcr.io/legido-ai-workspace/claude-code:latest
```

> 🎉 **That's it!** You're ready to use Claude Code in a secure container environment.

## ⚙️ Advanced Configuration

### 📋 Step-by-Step Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/legido-ai-workspace/docker-claude-code.git
   cd docker-claude-code
   ```

2. **Create your environment configuration:**
   ```bash
   cp .env.example .env
   ```

3. **Customize your configuration as needed:**

#### Complete Configuration Example:
```env
# System Configuration
DOCKER_GID=998
CONTAINER_NAME=my-claude-code
TZ=Europe/Madrid

# Volume Paths (customize as needed)
VOLUME_CONFIG=$HOME/.claude
VOLUME_PROJECTS=$PWD/projects
PORT=8080

# Optional: AWS Configuration
AWS_ACCESS_KEY_ID=your_aws_key
AWS_SECRET_ACCESS_KEY=your_aws_secret
AWS_DEFAULT_REGION=eu-west-1
```

## 🚀 Deployment Options

### Option 1: 📦 Pre-built Image (Recommended)

Pull and run the optimized image directly from GitHub Container Registry:

```bash
# Pull the latest stable version
docker pull ghcr.io/legido-ai-workspace/claude-code:latest
```

#### 🎯 Interactive Mode (Development)
```bash
docker run -it --rm \
  --name claude-code-dev \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $HOME/.claude:/home/node \
  -v $PWD:/projects \
  ghcr.io/legido-ai-workspace/claude-code:latest \
  bash
```

#### 🔄 Daemon Mode (Production)
```bash
# Start as background service
docker run -d \
  --name claude-code-prod \
  --restart unless-stopped \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $HOME/.claude:/home/node \
  -v $HOME/projects:/projects \
  --env-file .env \
  ghcr.io/legido-ai-workspace/claude-code:latest

# Access the running container
docker exec -it claude-code-prod claude --help
```

#### 🐋 Docker Compose (Orchestrated)
```bash
# Using the included docker-compose.yml
docker-compose up -d

# Access the service
docker-compose exec claude-code claude
```

### Option 2: 🔨 Custom Build (Advanced Users)

Build your own optimized image with custom configurations:

#### 🖥️ Linux/macOS Build
```bash
# Get Docker group ID for proper permissions
export DOCKER_GID=$(getent group docker | cut -d: -f3)

# Build with optimization
docker build \
  --build-arg DOCKER_GID=$DOCKER_GID \
  --build-arg BUILDKIT_INLINE_CACHE=1 \
  --tag claude-code:local \
  --tag claude-code:$(date +%Y%m%d) \
  .
```

#### 🪟 Windows Build
```powershell
# PowerShell build command
$env:DOCKER_GID="998"
docker build --build-arg DOCKER_GID=$env:DOCKER_GID -t claude-code:local .
```

## 💡 Usage Examples

### 🎯 Basic Operations

#### Start Your Development Environment
```bash
# Quick development setup
docker run -it --rm \
  --name claude-dev \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $PWD:/projects \
  -v $HOME/.claude:/home/node \
  ghcr.io/legido-ai-workspace/claude-code:latest bash

# Inside the container
claude --help                    # View available commands
claude generate                  # Generate code
claude chat                      # Interactive chat mode
```

#### Production Deployment
```bash
# Long-running service
docker run -d \
  --name claude-prod \
  --restart unless-stopped \
  --memory=4g \
  --cpus=2 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /opt/projects:/projects:ro \
  -v claude-data:/home/node \
  --env-file production.env \
  ghcr.io/legido-ai-workspace/claude-code:latest

# Monitor the service
docker logs -f claude-prod
docker stats claude-prod
```

### 🐋 Docker-in-Docker Capabilities

Full Docker functionality within the container for advanced containerization workflows:

#### Container Management
```bash
# Access the container
docker exec -it claude-prod bash

# Inside container - full Docker CLI available
docker ps                           # List running containers
docker build -t my-app .           # Build images
docker run -d nginx                 # Run containers
docker-compose up -d                # Orchestrate services
docker system prune -f              # Clean up resources
```

## 🔌 MCP Server Configuration

Claude Code supports MCP (Model Context Protocol) servers to extend its capabilities. MCP servers can provide additional context, tools, and integrations.

### Adding MCP Servers

MCP servers can be added manually using the `claude mcp add-json` command. Configuration persists across container restarts and recreations when using proper volume mounting.

#### Prerequisites

Ensure the container mounts `/home/node` (not just `/home/node/.claude`) to persist the main configuration file:

```yaml
volumes:
  - ${VOLUME_CONFIG:-./config}:/home/node  # ✓ Correct - persists .claude.json
  - /var/run/docker.sock:/var/run/docker.sock
```

#### Example: GitHub MCP Server

Add a GitHub MCP server using GitHub App authentication.

**Automatic Environment Variable Substitution**: The container's `entrypoint.sh` automatically replaces environment variable references (like `$GITHUB_APP_ID`) with their actual values on startup. Simply add your configuration with variable references, then restart the container:

```bash
# Add MCP configuration with environment variable references
docker exec claude-code claude mcp add-json github '{"command":"docker","args":["run","-i","--rm","-e","GITHUB_APP_ID=$GITHUB_APP_ID","-e","GITHUB_PRIVATE_KEY=$GITHUB_PRIVATE_KEY","-e","GITHUB_INSTALLATION_ID=$GITHUB_INSTALLATION_ID","ghcr.io/legido-ai/mcp-github-app-auth:latest"],"trust":true,"timeout":30000}'

# Restart the container to apply environment variable substitution
docker restart claude-code
```

The entrypoint script automatically:
- Detects environment variable references (e.g., `$GITHUB_APP_ID`, `$GITHUB_PRIVATE_KEY`)
- Creates a timestamped backup of the original configuration
- Replaces all references with actual values from the container environment
- Notifies you that the substitution was performed

**Alternative**: You can still use the setup script (`utils/setup-mcp-github.sh`) which validates and expands variables in a single step without requiring a restart.

#### Example: n8n MCP Server

Add an n8n MCP server to enable Claude to interact with n8n workflows.

**Setup Requirements:**
- n8n instance with API access enabled
- n8n API key (generated in n8n Settings > API > API Keys)
- n8n API URL (e.g., `http://localhost:5678/api/v1`)

**Configuration Steps:**

1. Set required environment variables in your `.env` file:
```env
N8N_API_URL=http://localhost:5678/api/v1
N8N_API_KEY=n8n_api_your_key_here
N8N_WEBHOOK_USERNAME=username  # Optional
N8N_WEBHOOK_PASSWORD=password  # Optional
DEBUG=false  # Optional
```

2. Use the setup script (recommended method):
```bash
# Copy the script into the container
docker cp utils/setup-mcp-n8n.sh claude-code:/tmp/

# Run the setup script
docker exec claude-code bash /tmp/setup-mcp-n8n.sh
```

The setup script (`utils/setup-mcp-n8n.sh`) automatically:
- Validates required environment variables (N8N_API_URL, N8N_API_KEY)
- Expands environment variable values into the configuration
- Handles optional webhook authentication credentials
- Creates a backup of your existing configuration
- Updates the MCP server configuration with proper Docker arguments

**Capabilities:**
Once configured, Claude can:
- List and search n8n workflows
- Execute workflows with parameters
- Retrieve workflow execution results
- Manage workflow credentials (with proper permissions)

#### Verify Configuration

```bash
# List configured MCP servers
docker exec claude-code claude mcp list

# Expected output:
# Checking MCP server health...
# github: docker run -i --rm -e GITHUB_APP_ID=... - ✓ Connected
```

#### Configuration Persistence

MCP configuration is stored in `/home/node/.claude.json`. With proper volume mounting:

✅ **Persists** across container stops/starts
✅ **Persists** across container deletions/recreations
✅ **No reconfiguration needed** after container updates

#### Other MCP Server Examples

```bash
# Add context7 MCP server
docker exec claude-code claude mcp add-json context7 '{"command":"npx","args":["-y","@upstash/context7-mcp"],"trust":false,"timeout":30000}'

# Add custom stdio MCP server
docker exec claude-code claude mcp add --transport stdio my-server -- npx -y my-mcp-server

# Remove an MCP server
docker exec claude-code claude mcp remove github

# Get details about a server
docker exec claude-code claude mcp get github
```

### Troubleshooting MCP

**Configuration not persisting?**
- Ensure volume mounts `/home/node` (not `/home/node/.claude`)
- Check that `${VOLUME_CONFIG}` directory exists on host
- Verify file ownership matches container user

**MCP server connection fails?**
- Check environment variables are passed to container
- Verify Docker socket is mounted: `-v /var/run/docker.sock:/var/run/docker.sock`
- Ensure MCP server image is accessible

**"Could not parse the provided public key" error (GitHub MCP)?**
This error occurs when environment variables in the MCP configuration are not properly expanded:
- **Problem**: Using `$GITHUB_PRIVATE_KEY` in the configuration but container wasn't restarted
- **Solution**: After adding MCP configuration with `docker exec claude mcp add-json`, restart the container with `docker restart claude-code` to apply environment variable substitution
- **Alternative**: Use the `utils/setup-mcp-github.sh` script which expands variables immediately without requiring restart
- To verify: Run `docker exec claude-code cat /home/node/.claude.json` and check if you see `$GITHUB_APP_ID` or the actual value like `1957234`

**n8n MCP connection fails?**
- Verify n8n API URL is accessible from the container (include `/api/v1` at the end)
- Check n8n API key is valid and has proper permissions
- Ensure Docker socket is mounted: `-v /var/run/docker.sock:/var/run/docker.sock`
- Verify environment variables are set in the container
- Use the setup script: `docker exec claude-code bash /tmp/setup-mcp-n8n.sh`
- Check n8n instance is running and API is enabled

## 🔄 Maintenance & Updates

### Update to Latest Version
```bash
# Stop existing container gracefully
docker stop claude-code
docker rm claude-code

# Pull latest image
docker pull ghcr.io/legido-ai-workspace/claude-code:latest

# Restart with new version
docker run -d \
  --name claude-code \
  --restart unless-stopped \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $HOME/.claude:/home/node \
  -v $PWD:/projects \
  ghcr.io/legido-ai-workspace/claude-code:latest
```

### Health Monitoring
```bash
# Check container health
docker inspect claude-code --format='{{.State.Health.Status}}'

# View health check logs
docker inspect claude-code --format='{{range .State.Health.Log}}{{.Output}}{{end}}'

# Monitor resource usage
docker stats claude-code --no-stream
```

### Backup & Restore
```bash
# Backup Claude configuration and data
docker run --rm \
  -v claude-data:/source:ro \
  -v $HOME/backups:/backup \
  alpine:latest \
  tar czf /backup/claude-backup-$(date +%Y%m%d).tar.gz -C /source .

# Restore from backup
docker run --rm \
  -v claude-data:/target \
  -v $HOME/backups:/backup:ro \
  alpine:latest \
  tar xzf /backup/claude-backup-20241016.tar.gz -C /target
```

## 📂 Volume Management

### Standard Volume Mounts

| Volume Path | Purpose | Recommended Local Path | Notes |
|-------------|---------|----------------------|-------|
| `/projects` | 📁 **Project Files** | `$PWD` or `$HOME/projects` | Your source code and workspaces |
| `/home/node` | ⚙️ **Claude Configuration** | `$HOME/.claude` | Settings, cache, configurations, and MCP servers |
| `/var/run/docker.sock` | 🐳 **Docker Socket** | `/var/run/docker.sock` | Docker-in-Docker functionality |
| `/tmp` | 🗂️ **Temporary Files** | `tmpfs` | Fast temporary storage |

### Volume Creation & Management
```bash
# Create named volumes for persistent data
docker volume create claude-config
docker volume create claude-projects
docker volume create claude-cache

# Use named volumes in production
docker run -d \
  --name claude-prod \
  -v claude-config:/home/node \
  -v claude-projects:/projects \
  -v claude-cache:/tmp \
  -v /var/run/docker.sock:/var/run/docker.sock \
  ghcr.io/legido-ai-workspace/claude-code:latest

# Inspect volume usage
docker volume ls
docker system df -v
```

### Performance Optimization
```bash
# Use tmpfs for temporary files (faster performance)
docker run -it --rm \
  --tmpfs /tmp:rw,size=1g,mode=1777 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $PWD:/projects \
  ghcr.io/legido-ai-workspace/claude-code:latest
```

## 🛡️ Security Features

### Built-in Security Measures

| Security Layer | Implementation | Benefit |
|---------------|----------------|---------|
| 👤 **Non-root Execution** | Runs as `node` user (UID 1000) | Prevents privilege escalation |
| 📦 **Minimal Base Image** | Debian Bookworm Slim | Reduced attack surface |
| 🔒 **Multi-stage Build** | Separated build/runtime environments | No build tools in production |
| 🔐 **Docker Socket Access** | Controlled group permissions | Secure Docker-in-Docker |
| 🚫 **No SSH/Remote Access** | Container-only execution | Prevents unauthorized access |

### Security Best Practices

#### Container Security
```bash
# Run with security options
docker run -d \
  --name claude-secure \
  --read-only \
  --tmpfs /tmp \
  --tmpfs /var/tmp \
  --security-opt=no-new-privileges:true \
  --cap-drop=ALL \
  --cap-add=DAC_OVERRIDE \
  -v /var/run/docker.sock:/var/run/docker.sock \
  ghcr.io/legido-ai-workspace/claude-code:latest
```

### Vulnerability Scanning
```bash
# Scan image for vulnerabilities
docker scout cves ghcr.io/legido-ai-workspace/claude-code:latest

# Check for outdated dependencies
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image ghcr.io/legido-ai-workspace/claude-code:latest
```

## 🔧 Troubleshooting

### Common Issues & Solutions

#### ❌ Permission Denied (Docker Socket)
```bash
# Problem: Cannot access Docker daemon
Error: permission denied while trying to connect to the Docker daemon socket

# Solution: Fix Docker group permissions
sudo usermod -aG docker $USER
newgrp docker

# Or run with sudo (not recommended for production)
sudo docker run ...
```

#### ❌ Port Already in Use
```bash
# Problem: Port conflict
Error: bind: address already in use

# Solution: Check and kill process using port
sudo lsof -i :8080
sudo kill -9 <PID>

# Or use different port
docker run -p 8081:8080 ...
```

#### ❌ Out of Disk Space
```bash
# Problem: No space left on device
Error: no space left on device

# Solution: Clean Docker resources
docker system prune -af --volumes
docker builder prune -af

# Check disk usage
docker system df
```

#### ❌ Container Startup Issues
```bash
# Problem: Container exits immediately
Error: Container claude-code exited with code 1

# Solution: Check logs and health
docker logs claude-code
docker inspect claude-code --format='{{.State.Health.Status}}'

# Debug with interactive mode
docker run -it --rm --entrypoint bash ghcr.io/legido-ai-workspace/claude-code:latest
```

### Performance Optimization

#### Memory Issues
```bash
# Monitor memory usage
docker stats claude-code --no-stream

# Limit memory usage
docker run -m 4g --oom-kill-disable ghcr.io/legido-ai-workspace/claude-code:latest
```

#### CPU Optimization
```bash
# Limit CPU usage
docker run --cpus="2.0" ghcr.io/legido-ai-workspace/claude-code:latest

# Set CPU priority
docker run --cpu-shares 512 ghcr.io/legido-ai-workspace/claude-code:latest
```

### Getting Help

- 📚 **Documentation**: [Project Wiki](https://github.com/legido-ai-workspace/docker-claude-code/wiki)
- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/legido-ai-workspace/docker-claude-code/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/legido-ai-workspace/docker-claude-code/discussions)
- 📧 **Email Support**: [support@legido.com](mailto:support@legido.com)

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

**Claude Code** is licensed under separate terms - see [Anthropic Claude Code](https://github.com/anthropic-ai/claude-code) for details.

---

<div align="center">

**🌟 Star this repository if you find it useful! 🌟**

[![GitHub stars](https://img.shields.io/github/stars/legido-ai-workspace/docker-claude-code?style=social)](https://github.com/legido-ai-workspace/docker-claude-code)
[![GitHub forks](https://img.shields.io/github/forks/legido-ai-workspace/docker-claude-code?style=social)](https://github.com/legido-ai-workspace/docker-claude-code/fork)

*Built with ❤️ by the [Legido AI Workspace](https://github.com/legido-ai-workspace) team*

</div>