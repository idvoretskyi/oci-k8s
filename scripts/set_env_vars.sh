#!/bin/bash

CONFIG_FILE="$HOME/.oci/config"
echo "# Setting OCI environment variables from $CONFIG_FILE"

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

# Output commands to set environment variables
echo "export TF_VAR_tenancy_ocid=\"$TENANCY_OCID\""
echo "export TF_VAR_user_ocid=\"$USER_OCID\"" 
echo "export TF_VAR_fingerprint=\"$FINGERPRINT\""
echo "export TF_VAR_private_key_path=\"$KEY_FILE\""
echo "export TF_VAR_region=\"$REGION\""

echo ""
echo "# You can use these commands directly:"
echo "eval \"\$(./scripts/set_env_vars.sh)\""
echo ""
echo "# Or you can use the OCI environment variables directly:"
echo "export OCI_CLI_USER=\"$USER_OCID\""
echo "export OCI_CLI_TENANCY=\"$TENANCY_OCID\""
echo "export OCI_CLI_FINGERPRINT=\"$FINGERPRINT\"" 
echo "export OCI_CLI_KEY_FILE=\"$KEY_FILE\""
echo "export OCI_CLI_REGION=\"$REGION\""
