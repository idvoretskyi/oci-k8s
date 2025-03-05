#!/bin/bash

CONFIG_FILE="$HOME/.oci/config"
KEY_FILE=$(grep "^key_file" "$CONFIG_FILE" | cut -d "=" -f2 | tr -d '[:space:]')

# Expand ~ to $HOME if needed
if [[ "$KEY_FILE" == "~/"* ]]; then
  KEY_FILE="${KEY_FILE/#\~/$HOME}"
fi

# Extract values from OCI config file
USER_OCID=$(grep "^user" "$CONFIG_FILE" | cut -d "=" -f2 | tr -d '[:space:]')
FINGERPRINT=$(grep "^fingerprint" "$CONFIG_FILE" | cut -d "=" -f2 | tr -d '[:space:]')
TENANCY=$(grep "^tenancy" "$CONFIG_FILE" | cut -d "=" -f2 | tr -d '[:space:]')
REGION=$(grep "^region" "$CONFIG_FILE" | cut -d "=" -f2 | tr -d '[:space:]')

# Read private key content
PRIVATE_KEY=$(cat "$KEY_FILE")

# Display instructions for setting environment variables
echo "# Run these commands to set your OCI credentials as environment variables:"
echo "export TF_VAR_user_ocid=\"$USER_OCID\""
echo "export TF_VAR_fingerprint=\"$FINGERPRINT\""
echo "export TF_VAR_tenancy_ocid=\"$TENANCY\""
echo "export TF_VAR_region=\"$REGION\""
echo "export TF_VAR_private_key_path=\"$KEY_FILE\""

echo ""
echo "# After running these commands, try Terraform again with:"
echo "cd tf"
echo "terraform init"
echo "terraform apply"
