#!/bin/bash

CONFIG_FILE="$HOME/.oci/config"

# Extract key file path from config
KEY_FILE=$(grep "^key_file" "$CONFIG_FILE" | cut -d "=" -f2 | tr -d '[:space:]')

# Expand ~ to $HOME if present
if [[ "$KEY_FILE" == "~/"* ]]; then
    KEY_FILE="${KEY_FILE/#\~/$HOME}"
fi

# Check if key file exists
if [ ! -f "$KEY_FILE" ]; then
    echo "ERROR: Key file $KEY_FILE does not exist!"
    exit 1
fi

# Read and format the private key for Terraform
# This handles multi-line formatting with heredoc style
echo "private_key = <<EOF"
cat "$KEY_FILE"
echo "EOF"
