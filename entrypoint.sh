#!/bin/bash
set -e

CONFIG_FILE="/home/node/.claude.json"

# Function to process environment variable replacements
process_env_vars() {
    local config_file="$1"

    # Check if config file exists
    if [ ! -f "$config_file" ]; then
        echo "Configuration file not found: $config_file"
        return 0
    fi

    # Get content of configuration file
    config_content=$(cat "$config_file")

    # Check if there are any environment variable references (pattern: $VAR_NAME)
    if ! echo "$config_content" | grep -q '\$[A-Za-z_][A-Za-z0-9_]*'; then
        echo "No environment variable references found in $config_file"
        return 0
    fi

    # Track if we need to make replacements
    needs_replacement=false

    # Get current environment variables
    while IFS='=' read -r env_var env_value; do
        # Skip if env_var is empty
        [ -z "$env_var" ] && continue

        # Check if this environment variable is referenced in the config file
        if echo "$config_content" | grep -q "\$$env_var"; then
            needs_replacement=true
            break
        fi
    done < <(env)

    # If replacements are needed, perform them
    if [ "$needs_replacement" = true ]; then
        # Create backup with timestamp
        timestamp=$(date +%s)
        backup_file="${config_file}.${timestamp}"
        cp "$config_file" "$backup_file"
        echo "Created backup: $backup_file"

        # Perform replacements
        new_content="$config_content"
        while IFS='=' read -r env_var env_value; do
            # Skip if env_var is empty
            [ -z "$env_var" ] && continue

            # Check if this environment variable is referenced in the config file
            if echo "$new_content" | grep -q "\$$env_var"; then
                # Escape special characters in the replacement value for sed
                escaped_value=$(echo "$env_value" | sed 's/[&/\]/\\&/g')
                new_content=$(echo "$new_content" | sed "s/\$$env_var/$escaped_value/g")
                echo "Replaced \$$env_var with actual value"
            fi
        done < <(env)

        # Write the modified content back to the config file
        echo "$new_content" > "$config_file"

        echo ""
        echo "=========================================="
        echo "Configuration file has been updated: $config_file"
        echo "A restart is required to pick up the changes"
        echo "=========================================="
        echo ""
    fi
}

# Process environment variables in the configuration file
process_env_vars "$CONFIG_FILE"

# Execute the main command (passed as arguments to this script)
exec "$@"
