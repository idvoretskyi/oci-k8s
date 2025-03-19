#!/bin/bash
# Consolidated OCI authentication utilities
# This script combines common authentication functions

# Check OCI config file
function check_oci_config() {
  local CONFIG_FILE="$HOME/.oci/config"
  local KEY_FILE=$(grep "^key_file" "$CONFIG_FILE" | cut -d "=" -f2 | tr -d '[:space:]')
  
  # Expand ~ to $HOME if present
  if [[ "$KEY_FILE" == "~/"* ]]; then
    KEY_FILE="${KEY_FILE/#\~/$HOME}"
  fi

  # Fix permissions if needed
  if [ -f "$KEY_FILE" ]; then
    chmod 600 "$KEY_FILE"
    echo "Ensured private key has proper permissions"
  fi
  
  # Check if key has OCI_API_KEY label
  if [ -f "$KEY_FILE" ] && ! grep -q "OCI_API_KEY" "$KEY_FILE"; then
    echo "Adding OCI_API_KEY label to private key"
    echo "" >> "$KEY_FILE"
    echo "OCI_API_KEY" >> "$KEY_FILE"
  fi
}

# Setup environment variables
function setup_env_vars() {
  local CONFIG_FILE="$HOME/.oci/config"
  
  export SUPPRESS_LABEL_WARNING=True
  export TF_VAR_tenancy_ocid=$(grep "^tenancy" "$CONFIG_FILE" | cut -d "=" -f2 | tr -d '[:space:]')
  export TF_VAR_user_ocid=$(grep "^user" "$CONFIG_FILE" | cut -d "=" -f2 | tr -d '[:space:]')
  export TF_VAR_fingerprint=$(grep "^fingerprint" "$CONFIG_FILE" | cut -d "=" -f2 | tr -d '[:space:]')
  export TF_VAR_private_key_path=$(grep "^key_file" "$CONFIG_FILE" | cut -d "=" -f2 | tr -d '[:space:]')
  export TF_VAR_region=$(grep "^region" "$CONFIG_FILE" | cut -d "=" -f2 | tr -d '[:space:]')
  
  # Also set OCI CLI variables
  export OCI_CLI_USER="$TF_VAR_user_ocid"
  export OCI_CLI_TENANCY="$TF_VAR_tenancy_ocid"
  export OCI_CLI_FINGERPRINT="$TF_VAR_fingerprint"
  export OCI_CLI_KEY_FILE="$TF_VAR_private_key_path"
  export OCI_CLI_REGION="$TF_VAR_region"
  
  echo "Environment variables have been set"
}

# Test OCI authentication
function test_auth() {
  echo "Testing OCI authentication..."
  oci iam region list --output table
}
