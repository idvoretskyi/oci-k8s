#!/bin/bash

SOURCE_KEY="/Users/idv/.oci/oci_api_key.pem"
TARGET_DIR="/Users/idv/GitHub/idvoretskyi/terraform-oci-k8s/tf/keys"
TARGET_KEY="$TARGET_DIR/oci_api_key.pem"

echo "Copying OCI key for local use..."

# Create keys directory
mkdir -p "$TARGET_DIR"
chmod 700 "$TARGET_DIR"

# Copy key and set proper permissions
cp "$SOURCE_KEY" "$TARGET_KEY"
chmod 600 "$TARGET_KEY"

echo "Key copied to $TARGET_KEY"
echo ""
echo "Update your terraform.tfvars file to use:"
echo "private_key_path = \"$TARGET_KEY\""
