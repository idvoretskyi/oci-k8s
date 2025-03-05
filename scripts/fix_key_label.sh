#!/bin/bash

KEY_FILE="$HOME/.oci/oci_api_key.pem"
BACKUP_FILE="$KEY_FILE.$(date +%Y%m%d%H%M%S).backup"

echo "Fixing OCI API key format to comply with Oracle's requirements..."

# Check if key file exists
if [ ! -f "$KEY_FILE" ]; then
  echo "ERROR: Key file not found at $KEY_FILE"
  exit 1
fi

# Backup existing key
echo "Creating backup of original key at $BACKUP_FILE"
cp "$KEY_FILE" "$BACKUP_FILE"

# Check if the label already exists
if grep -q "OCI_API_KEY" "$KEY_FILE"; then
  echo "Key file already has the OCI_API_KEY label - no changes needed"
else
  echo "Adding OCI_API_KEY label to the key file"
  # Add the label at the end of the file
  echo "OCI_API_KEY" >> "$KEY_FILE"
  
  # Verify that the key is still valid after modification
  if openssl rsa -in "$KEY_FILE" -noout &>/dev/null; then
    echo "SUCCESS: Label added and key is still valid"
  else
    echo "ERROR: Key is no longer valid after adding label! Restoring backup..."
    cp "$BACKUP_FILE" "$KEY_FILE"
    echo "Original key restored. Please try manually adding 'OCI_API_KEY' on a new line at the end of the file."
    exit 1
  fi
fi

echo "Testing updated key with OCI CLI..."
if oci iam region list &>/dev/null; then
  echo "SUCCESS: Key authentication works with OCI CLI!"
  echo "You can now run Terraform again:"
  echo "cd tf && terraform init && terraform apply"
else
  echo "WARNING: Key authentication still fails with OCI CLI."
  echo "Try one of these additional steps:"
  echo "1. Set the environment variable: export SUPPRESS_LABEL_WARNING=True"
  echo "2. Try regenerating the key: ./scripts/regenerate_keys.sh"
  echo "3. Check the OCI configuration: ./scripts/verify_fingerprint.sh"
fi
