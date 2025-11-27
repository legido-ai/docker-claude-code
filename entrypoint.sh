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
        echo "Configuration file not found: $config_file"
        return 0
    fi

    # Check if there are any environment variable references (pattern: $VAR_NAME)
    if ! grep -q '\$[A-Za-z_][A-Za-z0-9_]*' "$config_file"; then
        echo "No environment variable references found in $config_file"
        return 0
    fi

    echo "Found environment variable references in $config_file"

    # Create backup with timestamp
    timestamp=$(date +%s)
    backup_file="${config_file}.${timestamp}"
    cp "$config_file" "$backup_file"
    echo "Created backup: $backup_file"

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

            echo "Replaced \$$var_name with actual value"
        else
            echo "Warning: \$$var_name not found in environment, keeping as-is"
        fi
    done

    echo ""
    echo "=========================================="
    echo "Configuration file has been updated: $config_file"
    echo "A restart is required to pick up the changes"
    echo "=========================================="
    echo ""
}

# Process environment variables in the configuration file
process_env_vars "$CONFIG_FILE"

# Execute the main command (passed as arguments to this script)
exec "$@"
