#!/bin/bash
set -e

CONFIG_FILE="/home/node/.claude.json"

# Function to escape string for sed replacement (handles multiline)
escape_for_sed() {
    # Read the entire input preserving newlines
    local input
    input=$(cat)
    # Escape backslashes first, then forward slashes and ampersands
    # Then escape newlines for sed
    printf '%s' "$input" | sed -e 's/[\/&]/\\&/g' | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\n/g'
}

# Function to process environment variable replacements
process_env_vars() {
    local config_file="$1"

    # Check if config file exists
    if [ ! -f "$config_file" ]; then
        echo "[ENV-EXPAND] Config file not found at $config_file, skipping"
        return 0
    fi

    # Check if there are any environment variable references (pattern: $VAR_NAME)
    if ! grep -q '\$[A-Za-z_][A-Za-z0-9_]*' "$config_file"; then
        echo "[ENV-EXPAND] No environment variable references found"
        return 0
    fi

    echo "[ENV-EXPAND] Found environment variable references in $config_file"

    # Create backup with timestamp
    timestamp=$(date +%s)
    backup_file="${config_file}.backup.${timestamp}"
    cp "$config_file" "$backup_file"
    echo "[ENV-EXPAND] Created backup: $backup_file"

    # Get all unique variable names from the config file
    var_names=$(grep -o '\$[A-Za-z_][A-Za-z0-9_]*' "$config_file" | sed 's/^\$//' | sort -u)

    # Process replacements
    for var_name in $var_names; do
        # Check if the environment variable exists using indirect expansion
        if [ -n "${!var_name+x}" ]; then
            # Get the value
            var_value="${!var_name}"

            # Escape the value for sed
            escaped_value=$(printf '%s' "$var_value" | escape_for_sed)

            # Perform the replacement
            sed -i "s/\$$var_name/$escaped_value/g" "$config_file"

            echo "[ENV-EXPAND] Replaced \$$var_name with actual value"
        else
            echo "[ENV-EXPAND] Warning: \$$var_name not found in environment, keeping as-is"
        fi
    done

    echo "[ENV-EXPAND] Environment variable expansion completed successfully"
}

# Process environment variables once at boot time
process_env_vars "$CONFIG_FILE"

# Execute the main command (passed as arguments to this script)
exec "$@"
