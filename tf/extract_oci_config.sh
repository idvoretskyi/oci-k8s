#!/bin/bash

CONFIG_FILE="$HOME/.oci/config"

# Extract values from OCI config file
USER_OCID=$(grep "^user" "$CONFIG_FILE" | cut -d "=" -f2 | tr -d '[:space:]')
FINGERPRINT=$(grep "^fingerprint" "$CONFIG_FILE" | cut -d "=" -f2 | tr -d '[:space:]')

# Output as JSON for Terraform external data source
echo "{ \"user_ocid\": \"$USER_OCID\", \"fingerprint\": \"$FINGERPRINT\" }"
