#!/bin/bash
set -e

# Function to check if running in Docker
check_docker_access() {
  if [ -S /var/run/docker.sock ]; then
    echo "✓ Docker socket access available"
  else
    echo "⚠ Docker socket not available - Docker-in-Docker features will not work"
  fi
}

# Function to initialize Claude configuration
init_claude_config() {
  if [ ! -d "$HOME/.claude" ]; then
    mkdir -p "$HOME/.claude"
    echo "Initialized Claude configuration directory"
  fi
}

# Function to set up project directory
setup_project_dir() {
  if [ ! -d "/projects" ]; then
    mkdir -p /projects
    echo "Created projects directory"
  fi
}

# Display startup information
echo "🚀 Starting Claude Code Container"
echo "================================="
echo "User: $(whoami) ($(id -u):$(id -g))"
echo "Working directory: $(pwd)"
echo "Current time: $(date)"
echo ""

# Run initialization tasks
check_docker_access
init_claude_config
setup_project_dir

# Ensure proper permissions for history file
touch /commandhistory/.bash_history
chmod 600 /commandhistory/.bash_history

# Execute the container's original command
echo "Starting command: $*"
exec "$@"
