#!/bin/bash
#
# Setup script for configuring n8n MCP server in Claude Code
# This script properly expands environment variables when adding the MCP server configuration
#

set -e

echo "Configuring n8n MCP server for Claude Code..."

# Check if required environment variables are set
if [ -z "$N8N_API_URL" ] || [ -z "$N8N_API_KEY" ]; then
    echo "ERROR: Missing required environment variables!"
    echo "Please ensure the following environment variables are set:"
    echo "  - N8N_API_URL (e.g., http://localhost:5678/api/v1)"
    echo "  - N8N_API_KEY (e.g., n8n_api_...)"
    echo ""
    echo "Optional environment variables:"
    echo "  - N8N_WEBHOOK_USERNAME (for webhook authentication)"
    echo "  - N8N_WEBHOOK_PASSWORD (for webhook authentication)"
    echo "  - DEBUG (set to 'true' for debug logging)"
    exit 1
fi

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo "ERROR: python3 is required but not found in PATH"
    exit 1
fi

# Ensure .claude.json exists
if [ ! -f "$HOME/.claude.json" ]; then
    echo "Creating $HOME/.claude.json..."
    echo '{}' > "$HOME/.claude.json"
fi

# Use Python to safely update the JSON configuration with expanded environment variables
python3 << 'EOFPYTHON'
import json
import os
import sys

config_path = os.path.expanduser("~/.claude.json")

# Read the current config
try:
    with open(config_path, "r") as f:
        config = json.load(f)
except Exception as e:
    print(f"ERROR: Failed to read {config_path}: {e}", file=sys.stderr)
    sys.exit(1)

# Get environment variables with actual values
n8n_api_url = os.environ.get("N8N_API_URL")
n8n_api_key = os.environ.get("N8N_API_KEY")
n8n_webhook_username = os.environ.get("N8N_WEBHOOK_USERNAME", "")
n8n_webhook_password = os.environ.get("N8N_WEBHOOK_PASSWORD", "")
debug = os.environ.get("DEBUG", "false")

if not all([n8n_api_url, n8n_api_key]):
    print("ERROR: Missing required environment variables", file=sys.stderr)
    sys.exit(1)

# Build the docker args list
docker_args = [
    "run",
    "-i",
    "--rm",
    "-e",
    f"N8N_API_URL={n8n_api_url}",
    "-e",
    f"N8N_API_KEY={n8n_api_key}"
]

# Add optional webhook credentials if provided
if n8n_webhook_username:
    docker_args.extend(["-e", f"N8N_WEBHOOK_USERNAME={n8n_webhook_username}"])
if n8n_webhook_password:
    docker_args.extend(["-e", f"N8N_WEBHOOK_PASSWORD={n8n_webhook_password}"])

# Add debug flag if set
if debug.lower() == "true":
    docker_args.extend(["-e", "DEBUG=true"])

# Add the Docker image
docker_args.append("leonardsellem/n8n-mcp-server:latest")

# Create MCP server configuration with expanded values
mcp_config = {
    "command": "docker",
    "args": docker_args
}

# Get current working directory
cwd = os.getcwd()

# Initialize nested structure if needed
if "projects" not in config:
    config["projects"] = {}
if cwd not in config["projects"]:
    config["projects"][cwd] = {}
if "mcpServers" not in config["projects"][cwd]:
    config["projects"][cwd]["mcpServers"] = {}

# Add/update the n8n MCP server
config["projects"][cwd]["mcpServers"]["n8n"] = mcp_config

# Create backup
backup_path = f"{config_path}.backup"
try:
    with open(config_path, "r") as f:
        with open(backup_path, "w") as b:
            b.write(f.read())
except Exception:
    pass  # Ignore backup errors

# Write back the updated config
try:
    with open(config_path, "w") as f:
        json.dump(config, f, indent=2)
    print(f"✓ MCP configuration updated successfully for project: {cwd}")
    print(f"✓ Backup saved to: {backup_path}")
except Exception as e:
    print(f"ERROR: Failed to write {config_path}: {e}", file=sys.stderr)
    sys.exit(1)

EOFPYTHON

echo ""
echo "n8n MCP server configured successfully!"
echo ""
echo "To verify the configuration, run:"
echo "  claude mcp list"
echo ""
echo "NOTE: This configuration uses expanded environment variable values."
echo "If you change your n8n API credentials, you must run this script again."
echo ""
echo "Required environment variables that were configured:"
echo "  - N8N_API_URL: $N8N_API_URL"
echo "  - N8N_API_KEY: [REDACTED]"
if [ -n "$N8N_WEBHOOK_USERNAME" ]; then
    echo "  - N8N_WEBHOOK_USERNAME: $N8N_WEBHOOK_USERNAME"
fi
if [ -n "$N8N_WEBHOOK_PASSWORD" ]; then
    echo "  - N8N_WEBHOOK_PASSWORD: [REDACTED]"
fi
if [ "$DEBUG" = "true" ]; then
    echo "  - DEBUG: true"
fi
echo ""
