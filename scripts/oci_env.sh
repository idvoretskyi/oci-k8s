#!/bin/bash

# This script exports OCI environment variables directly
# Usage: source ./scripts/oci_env.sh

CONFIG_FILE="$HOME/.oci/config"

# Extract values
USER_OCID=$(grep "^user" "$CONFIG_FILE" | cut -d "=" -f2 | tr -d '[:space:]')
FINGERPRINT=$(grep "^fingerprint" "$CONFIG_FILE" | cut -d "=" -f2 | tr -d '[:space:]')
TENANCY_OCID=$(grep "^tenancy" "$CONFIG_FILE" | cut -d "=" -f2 | tr -d '[:space:]')
REGION=$(grep "^region" "$CONFIG_FILE" | cut -d "=" -f2 | tr -d '[:space:]')
KEY_FILE=$(grep "^key_file" "$CONFIG_FILE" | cut -d "=" -f2 | tr -d '[:space:]')

# Expand ~ to $HOME if present
if [[ "$KEY_FILE" == "~/"* ]]; then
    KEY_FILE="${KEY_FILE/#\~/$HOME}"
fi

# Export environment variables directly
export TF_VAR_tenancy_ocid="$TENANCY_OCID"
export TF_VAR_user_ocid="$USER_OCID"
export TF_VAR_fingerprint="$FINGERPRINT"
export TF_VAR_private_key_path="$KEY_FILE"
export TF_VAR_region="$REGION"

# Also export OCI CLI variables for good measure
export OCI_CLI_USER="$USER_OCID"
export OCI_CLI_TENANCY="$TENANCY_OCID"
export OCI_CLI_FINGERPRINT="$FINGERPRINT"
export OCI_CLI_KEY_FILE="$KEY_FILE"
export OCI_CLI_REGION="$REGION"

echo "OCI environment variables have been exported."
echo "You can now run: terraform init && terraform apply"
