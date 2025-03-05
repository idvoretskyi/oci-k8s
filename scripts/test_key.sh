#!/bin/bash

# This script tests if the private key is readable and valid

KEY_PATH="/Users/idv/.oci/oci_api_key.pem"
CONFIG_FILE="$HOME/.oci/config"

echo "Testing OCI private key at: $KEY_PATH"

# Check if key file exists
if [ ! -f "$KEY_PATH" ]; then
  echo "ERROR: Key file does not exist at $KEY_PATH"
  exit 1
fi

# Check permissions
if [[ "$OSTYPE" == "darwin"* ]]; then
  PERMS=$(stat -f %Lp "$KEY_PATH")
else
  PERMS=$(stat -c %a "$KEY_PATH")
fi

echo "Key file permissions: $PERMS"

# Check if file is readable
if [ ! -r "$KEY_PATH" ]; then
  echo "ERROR: Key file is not readable"
  exit 1
fi

# Test if OpenSSL can read the key
echo "Testing if OpenSSL can read the key..."
if openssl rsa -in "$KEY_PATH" -noout 2>/dev/null; then
  echo "SUCCESS: Key is valid and readable by OpenSSL"
else
  echo "ERROR: OpenSSL couldn't read the key. It might be corrupted or in the wrong format."
  exit 1
fi

# Extract fingerprint from config
echo "Extracting fingerprint from OCI config..."
FINGERPRINT=$(grep "^fingerprint" "$CONFIG_FILE" | cut -d "=" -f2 | tr -d '[:space:]')

if [ -z "$FINGERPRINT" ]; then
  echo "WARNING: No fingerprint found in config file"
else
  echo "Fingerprint in config: $FINGERPRINT"
  
  # Generate fingerprint from key to compare
  echo "Generating fingerprint from key file..."
  GENERATED_FINGERPRINT=$(openssl rsa -pubout -outform DER -in "$KEY_PATH" 2>/dev/null | openssl md5 | awk '{print $2}' | sed 's/../&:/g' | sed 's/:$//')
  
  echo "Generated fingerprint: $GENERATED_FINGERPRINT"
  
  if [ "$FINGERPRINT" == "$GENERATED_FINGERPRINT" ]; then
    echo "SUCCESS: Fingerprints match"
  else
    echo "WARNING: Fingerprints do not match. The key file might not correspond to the fingerprint in your config."
  fi
fi

# Try to make a simple OCI CLI call
echo "Testing OCI CLI with this key..."
if oci iam region list --profile DEFAULT >/dev/null 2>&1; then
  echo "SUCCESS: OCI CLI works with this key"
else
  echo "ERROR: OCI CLI failed with this key"
  echo "Full OCI CLI output:"
  oci iam region list --profile DEFAULT
fi

echo "Key test complete."
