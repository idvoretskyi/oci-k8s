#!/bin/bash

CONFIG_FILE="$HOME/.oci/config"

# Extract key file path from config
KEY_FILE=$(grep "^key_file" "$CONFIG_FILE" | cut -d "=" -f2 | tr -d '[:space:]')

# Expand ~ to $HOME if present
if [[ "$KEY_FILE" == "~/"* ]]; then
    KEY_FILE="${KEY_FILE/#\~/$HOME}"
fi

echo "Checking OCI API key format at $KEY_FILE"

# Check if key file exists
if [ ! -f "$KEY_FILE" ]; then
    echo "ERROR: Key file not found at $KEY_FILE"
    exit 1
fi

# Check if the file has the OCI_API_KEY label
if grep -q "OCI_API_KEY" "$KEY_FILE"; then
    echo "SUCCESS: Key file has the required OCI_API_KEY label"
else
    echo "WARNING: Key file is missing the required OCI_API_KEY label"
    echo "This may cause authentication issues with OCI API calls"
    echo "Run the fix script: ./scripts/fix_key_label.sh"
fi

# Check if key is valid PEM format
if openssl rsa -in "$KEY_FILE" -noout &>/dev/null; then
    echo "SUCCESS: Key is valid PEM format"
else
    echo "ERROR: Key is not valid PEM format"
    echo "Try regenerating the key: ./scripts/regenerate_keys.sh"
fi

# Check if file ends with a newline
if [ "$(tail -c 1 "$KEY_FILE" | wc -l)" -eq 0 ]; then
    echo "WARNING: Key file does not end with a newline"
    echo "This might cause issues with the OCI_API_KEY label"
    echo "Run the fix script: ./scripts/fix_key_label.sh"
fi
