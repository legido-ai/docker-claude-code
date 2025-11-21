#!/bin/bash
#
# Setup script for configuring GitHub MCP server in Claude Code
# This script properly expands environment variables when adding the MCP server configuration
#

set -e

echo "Configuring GitHub MCP server for Claude Code..."

# Check if required environment variables are set
if [ -z "$GITHUB_APP_ID" ] || [ -z "$GITHUB_INSTALLATION_ID" ] || [ -z "$GITHUB_PRIVATE_KEY" ]; then
    echo "ERROR: Missing required environment variables!"
    echo "Please ensure the following environment variables are set:"
    echo "  - GITHUB_APP_ID"
    echo "  - GITHUB_INSTALLATION_ID"
    echo "  - GITHUB_PRIVATE_KEY"
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
github_app_id = os.environ.get("GITHUB_APP_ID")
github_installation_id = os.environ.get("GITHUB_INSTALLATION_ID")
github_private_key = os.environ.get("GITHUB_PRIVATE_KEY")

if not all([github_app_id, github_installation_id, github_private_key]):
    print("ERROR: Missing required environment variables", file=sys.stderr)
    sys.exit(1)

# Create MCP server configuration with expanded values
mcp_config = {
    "command": "docker",
    "args": [
        "run",
        "-i",
        "--rm",
        "-e",
        f"GITHUB_APP_ID={github_app_id}",
        "-e",
        f"GITHUB_PRIVATE_KEY={github_private_key}",
        "-e",
        f"GITHUB_INSTALLATION_ID={github_installation_id}",
        "ghcr.io/legido-ai/mcp-github-app-auth:latest"
    ]
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

# Add/update the github MCP server
config["projects"][cwd]["mcpServers"]["github"] = mcp_config

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
echo "GitHub MCP server configured successfully!"
echo ""
echo "To verify the configuration, run:"
echo "  claude mcp list"
echo ""
echo "NOTE: This configuration uses expanded environment variable values."
echo "If you change your GitHub App credentials, you must run this script again."
