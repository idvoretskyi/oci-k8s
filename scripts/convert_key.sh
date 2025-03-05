#!/bin/bash

SOURCE_KEY="/Users/idv/.oci/oci_api_key.pem"
TARGET_DIR="/Users/idv/GitHub/idvoretskyi/terraform-oci-k8s/tf/keys"
mkdir -p "$TARGET_DIR"
chmod 700 "$TARGET_DIR"

echo "Converting OCI key to different formats for compatibility testing..."

# Copy original key
cp "$SOURCE_KEY" "$TARGET_DIR/original.pem"
chmod 600 "$TARGET_DIR/original.pem"

# Convert to PKCS#1 PEM format (if not already)
openssl rsa -in "$SOURCE_KEY" -out "$TARGET_DIR/pkcs1.pem"
chmod 600 "$TARGET_DIR/pkcs1.pem"

# Convert to PKCS#8 PEM format
openssl pkcs8 -topk8 -nocrypt -in "$SOURCE_KEY" -out "$TARGET_DIR/pkcs8.pem"
chmod 600 "$TARGET_DIR/pkcs8.pem"

echo "Keys created in $TARGET_DIR:"
echo "1. original.pem - Original key file"
echo "2. pkcs1.pem - PKCS#1 PEM format"
echo "3. pkcs8.pem - PKCS#8 PEM format"
echo ""
echo "Try updating terraform.tfvars with one of these paths:"
echo "private_key_path = \"$TARGET_DIR/pkcs1.pem\"  # Try this one first"
echo "private_key_path = \"$TARGET_DIR/pkcs8.pem\"  # Try this if pkcs1 doesn't work"
