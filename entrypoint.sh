#!/bin/sh
set -e

# Function to expand environment variables in .claude.json
expand_env_vars() {
    local config_file="/home/node/.claude.json"

    # Check if .claude.json exists
    if [ ! -f "$config_file" ]; then
        echo "No .claude.json found, skipping environment variable expansion"
        return 0
    fi

    # Check if Python is available for JSON processing
    if ! command -v python3 >/dev/null 2>&1; then
        echo "Warning: python3 not found, skipping environment variable expansion"
        return 0
    fi

    echo "Expanding environment variables in .claude.json..."

    # Use Python to safely expand environment variables in JSON
    python3 << 'EOFPYTHON'
import json
import os
import re
import sys

config_path = "/home/node/.claude.json"

try:
    # Read the current config
    with open(config_path, "r") as f:
        content = f.read()

    # Store original content for backup
    original_content = content

    # Function to replace environment variables
    def replace_env_var(match):
        var_name = match.group(1) if match.group(1) else match.group(2)
        env_value = os.environ.get(var_name)
        if env_value is not None:
            # Properly escape the value for JSON
            return json.dumps(env_value)[1:-1]  # Remove outer quotes from json.dumps
        return match.group(0)  # Return original if env var not found

    # Replace ${VAR_NAME} pattern
    content = re.sub(r'\$\{([A-Z_][A-Z0-9_]*)\}', replace_env_var, content)

    # Replace $VAR_NAME pattern (but be careful not to match in the middle of strings)
    content = re.sub(r'\$([A-Z_][A-Z0-9_]*)', replace_env_var, content)

    # Check if any changes were made
    if content != original_content:
        # Validate that the result is still valid JSON
        try:
            json.loads(content)
        except json.JSONDecodeError as e:
            print(f"Error: Environment variable expansion resulted in invalid JSON: {e}", file=sys.stderr)
            sys.exit(1)

        # Create backup
        backup_path = f"{config_path}.backup"
        try:
            with open(backup_path, "w") as f:
                f.write(original_content)
        except Exception:
            pass  # Ignore backup errors

        # Write expanded content
        with open(config_path, "w") as f:
            f.write(content)

        print(f"✓ Environment variables expanded successfully")
        print(f"✓ Backup saved to: {backup_path}")
    else:
        print("No environment variables found to expand")

except FileNotFoundError:
    print(f"Config file not found: {config_path}")
except Exception as e:
    print(f"Error expanding environment variables: {e}", file=sys.stderr)
    sys.exit(1)

EOFPYTHON
}

# Run environment variable expansion
expand_env_vars

# Execute the container's original command (starts Claude Code)
exec "$@"
