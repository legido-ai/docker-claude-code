#!/bin/sh
set -e

# Function to expand environment variables in .claude.json
expand_env_vars() {
    local config_file="/home/node/.claude.json"

    echo "=== Environment Variable Expansion ==="
    echo "Checking for config file at: $config_file"

    # Check if .claude.json exists
    if [ ! -f "$config_file" ]; then
        echo "No .claude.json found, skipping environment variable expansion"
        echo "Note: File will be created by Claude Code on first run"
        return 0
    fi

    echo "✓ Config file found"

    # Check if Python is available for JSON processing
    if ! command -v python3 >/dev/null 2>&1; then
        echo "Warning: python3 not found, skipping environment variable expansion"
        return 0
    fi

    echo "✓ Python3 available"
    echo "Scanning for environment variables to expand..."

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

    # Track which variables we find and expand
    expanded_vars = []
    found_vars = []

    # Function to replace environment variables
    def replace_env_var(match):
        var_name = match.group(1) if match.group(1) else match.group(2)
        found_vars.append(var_name)
        env_value = os.environ.get(var_name)
        if env_value is not None:
            expanded_vars.append(var_name)
            # Properly escape the value for JSON
            # For security, don't log the actual value
            return json.dumps(env_value)[1:-1]  # Remove outer quotes from json.dumps
        return match.group(0)  # Return original if env var not found

    # Replace ${VAR_NAME} pattern
    content = re.sub(r'\$\{([A-Z_][A-Z0-9_]*)\}', replace_env_var, content)

    # Replace $VAR_NAME pattern (but be careful not to match in the middle of strings)
    content = re.sub(r'\$([A-Z_][A-Z0-9_]*)', replace_env_var, content)

    # Report what was found
    if found_vars:
        print(f"Found {len(set(found_vars))} environment variable(s) in config:")
        for var in set(found_vars):
            if var in expanded_vars:
                print(f"  ✓ ${var} -> expanded")
            else:
                print(f"  ✗ ${var} -> not set in environment (keeping as-is)")

    # Check if any changes were made
    if content != original_content:
        # Validate that the result is still valid JSON
        try:
            json.loads(content)
        except json.JSONDecodeError as e:
            print(f"Error: Environment variable expansion resulted in invalid JSON: {e}", file=sys.stderr)
            print("This may indicate a problem with special characters in environment variable values", file=sys.stderr)
            sys.exit(1)

        # Create backup
        backup_path = f"{config_path}.backup"
        try:
            with open(backup_path, "w") as f:
                f.write(original_content)
            print(f"✓ Backup saved to: {backup_path}")
        except Exception as e:
            print(f"Warning: Could not create backup: {e}", file=sys.stderr)

        # Write expanded content
        with open(config_path, "w") as f:
            f.write(content)

        print(f"✓ Configuration file updated with expanded environment variables")
    else:
        print("No environment variables found to expand")

except FileNotFoundError:
    print(f"Config file not found: {config_path}")
except PermissionError as e:
    print(f"Error: Permission denied when accessing config file: {e}", file=sys.stderr)
    print(f"Check file permissions: ls -la {config_path}", file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f"Error expanding environment variables: {e}", file=sys.stderr)
    import traceback
    traceback.print_exc()
    sys.exit(1)

EOFPYTHON

    echo "=== Environment Variable Expansion Complete ==="
    echo ""
}

# Run environment variable expansion on startup
expand_env_vars

# Start a background process to watch for changes to .claude.json and expand variables
# This ensures that even if users add MCP servers after container startup, variables get expanded
watch_and_expand() {
    local config_file="/home/node/.claude.json"
    local last_mtime=""
    local first_run=true

    echo "Starting background watcher for .claude.json changes..."

    # Initialize last_mtime if file exists
    if [ -f "$config_file" ]; then
        last_mtime=$(stat -c %Y "$config_file" 2>/dev/null || stat -f %m "$config_file" 2>/dev/null)
    fi

    while true; do
        sleep 5  # Check every 5 seconds

        if [ -f "$config_file" ]; then
            # Get the modification time of the file
            current_mtime=$(stat -c %Y "$config_file" 2>/dev/null || stat -f %m "$config_file" 2>/dev/null)

            # If modification time changed, expand variables
            if [ -n "$current_mtime" ] && [ "$current_mtime" != "$last_mtime" ]; then
                # Don't expand on the very first run if we initialized from existing file
                # (we already did that at startup), but DO expand on any subsequent changes
                if [ "$first_run" = true ] && [ -n "$last_mtime" ]; then
                    first_run=false
                else
                    echo ""
                    echo "=== Detected change in .claude.json ==="
                    expand_env_vars
                    first_run=false
                fi
                last_mtime="$current_mtime"
            fi
        else
            # File doesn't exist yet, wait for it to be created
            if [ -n "$last_mtime" ]; then
                # File was deleted
                last_mtime=""
            fi
        fi
    done
}

# Start the watcher in the background
watch_and_expand &

# Execute the container's original command (starts Claude Code)
exec "$@"
