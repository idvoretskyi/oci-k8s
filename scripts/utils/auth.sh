#!/bin/bash
# Consolidated authentication utilities for OCI

# Check if key file has the OCI_API_KEY label and add it if missing
function check_key_format() {
  local KEY_FILE="$1"
  
  # Check if the file has the OCI_API_KEY label
  if [ -f "$KEY_FILE" ] && ! grep -q "OCI_API_KEY" "$KEY_FILE"; then
    echo "Adding OCI_API_KEY label to the key file"
    echo "" >> "$KEY_FILE"  # Ensure there's a newline
    echo "OCI_API_KEY" >> "$KEY_FILE"
    echo "Label added to key file"
  fi
}

# Verify and fix private key permissions
function fix_key_permissions() {
  local KEY_FILE="$1"
  
  if [ -f "$KEY_FILE" ]; then
    chmod 600 "$KEY_FILE"
    echo "Key permissions set to 600"
  else
    echo "Key file not found at $KEY_FILE"
    return 1
  fi
}

# Verify OCI configuration
function verify_config() {
  local CONFIG_FILE="$HOME/.oci/config"
  local REQUIRED_KEYS=("user" "fingerprint" "key_file" "tenancy" "region")
  
  # Check if file exists
  if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Config file doesn't exist at $CONFIG_FILE"
    return 1
  fi
  
  # Check for each required key
  local MISSING=""
  for KEY in "${REQUIRED_KEYS[@]}"; do
    if ! grep -q "^$KEY\s*=" "$CONFIG_FILE"; then
      MISSING="$MISSING $KEY"
    fi
  done
  
  if [ ! -z "$MISSING" ]; then
    echo "ERROR: Missing required keys:$MISSING"
    return 1
  fi
  
  # Extract key file path
  local KEY_FILE=$(grep "^key_file" "$CONFIG_FILE" | cut -d "=" -f2 | tr -d '[:space:]')
  
  # Expand ~ to $HOME if present
  if [[ "$KEY_FILE" == "~/"* ]]; then
    KEY_FILE="${KEY_FILE/#\~/$HOME}"
  fi
  
  # Check if key file exists
  if [ ! -f "$KEY_FILE" ]; then
    echo "ERROR: Private key file doesn't exist at $KEY_FILE"
    return 1
  fi
  
  # Fix key permissions and format
  fix_key_permissions "$KEY_FILE"
  check_key_format "$KEY_FILE"
  
  return 0
}

# Generate new OCI API keys
function generate_keys() {
  local CONFIG_FILE="$HOME/.oci/config"
  local KEY_DIR="$HOME/.oci"
  local KEY_FILE="$KEY_DIR/oci_api_key.pem"
  local PUB_KEY_FILE="$KEY_DIR/oci_api_key_public.pem"
  
  mkdir -p "$KEY_DIR"
  chmod 700 "$KEY_DIR"
  
  # Generate private key
  openssl genrsa -out "$KEY_FILE" 2048
  chmod 600 "$KEY_FILE"
  
  # Add OCI_API_KEY label
  echo "" >> "$KEY_FILE"
  echo "OCI_API_KEY" >> "$KEY_FILE"
  
  # Generate public key
  openssl rsa -pubout -in "$KEY_FILE" -out "$PUB_KEY_FILE"
  
  # Generate fingerprint
  if [[ "$OSTYPE" == "darwin"* ]]; then
    FINGERPRINT=$(openssl rsa -pubout -outform DER -in "$KEY_FILE" 2>/dev/null | openssl md5 | awk '{print $2}' | sed 's/\(..\)/\1:/g; s/:$//')
  else
    FINGERPRINT=$(openssl rsa -pubout -outform DER -in "$KEY_FILE" 2>/dev/null | openssl md5 -c | awk '{print $2}')
  fi
  
  echo "New key pair generated:"
  echo "  Private key: $KEY_FILE"
  echo "  Public key: $PUB_KEY_FILE"
  echo "  Fingerprint: $FINGERPRINT"
  
  echo ""
  echo "Upload the public key to OCI Console and update your config with the fingerprint."
  echo ""
  echo "Public key content:"
  cat "$PUB_KEY_FILE"
  
  return 0
}

# Set environment variables for OCI
function set_env_variables() {
  local CONFIG_FILE="$HOME/.oci/config"
  
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
  
  # Set terraform variables
  export TF_VAR_user_ocid="$USER_OCID"
  export TF_VAR_fingerprint="$FINGERPRINT"
  export TF_VAR_tenancy_ocid="$TENANCY_OCID"
  export TF_VAR_region="$REGION"
  export TF_VAR_private_key_path="$KEY_FILE"
  
  # Set OCI CLI variables
  export OCI_CLI_USER="$USER_OCID"
  export OCI_CLI_TENANCY="$TENANCY_OCID"
  export OCI_CLI_FINGERPRINT="$FINGERPRINT"
  export OCI_CLI_KEY_FILE="$KEY_FILE"
  export OCI_CLI_REGION="$REGION"
  
  # Suppress the key label warning
  export SUPPRESS_LABEL_WARNING=True
  
  echo "Environment variables have been set for OCI authentication"
}

# Test OCI authentication
function test_auth() {
  echo "Testing OCI authentication..."
  oci iam region list --output table
  return $?
}
