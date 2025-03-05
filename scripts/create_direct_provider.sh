#!/bin/bash

CONFIG_FILE="$HOME/.oci/config"
OUTPUT_FILE="/Users/idv/GitHub/idvoretskyi/terraform-oci-k8s/tf/generated_provider.tf"

echo "Generating provider configuration with inline private key..."

# Extract values from config file
USER_OCID=$(grep "^user" "$CONFIG_FILE" | cut -d "=" -f2 | tr -d '[:space:]')
FINGERPRINT=$(grep "^fingerprint" "$CONFIG_FILE" | cut -d "=" -f2 | tr -d '[:space:]')
TENANCY_OCID=$(grep "^tenancy" "$CONFIG_FILE" | cut -d "=" -f2 | tr -d '[:space:]')
REGION=$(grep "^region" "$CONFIG_FILE" | cut -d "=" -f2 | tr -d '[:space:]')
KEY_FILE=$(grep "^key_file" "$CONFIG_FILE" | cut -d "=" -f2 | tr -d '[:space:]')

# Expand ~ to $HOME if present
if [[ "$KEY_FILE" == "~/"* ]]; then
    KEY_FILE="${KEY_FILE/#\~/$HOME}"
fi

# Check if key file exists
if [ ! -f "$KEY_FILE" ]; then
    echo "ERROR: Private key file doesn't exist at $KEY_FILE"
    exit 1
fi

# Read private key content
PRIVATE_KEY=$(cat "$KEY_FILE")

# Create provider configuration
cat > "$OUTPUT_FILE" << EOF
// THIS FILE IS GENERATED - DO NOT EDIT MANUALLY
// Created by create_direct_provider.sh

// Comment out the provider in main.tf before using this

provider "oci" {
  region       = "$REGION"
  tenancy_ocid = "$TENANCY_OCID" 
  user_ocid    = "$USER_OCID"
  fingerprint  = "$FINGERPRINT"
  
  // Private key included directly
  private_key = <<-EOF
$PRIVATE_KEY
EOF
}
EOF

echo "Provider configuration with inline key created at: $OUTPUT_FILE"
echo ""
echo "IMPORTANT: Comment out or remove the existing provider block in main.tf"
echo "           before running Terraform with this generated provider."
echo ""
echo "Next steps:"
echo "1. Edit main.tf to comment out the existing provider block"
echo "2. Run: cd tf && terraform init -reconfigure"
echo "3. Run: terraform apply"
