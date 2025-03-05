#!/bin/bash

CONFIG_FILE="$HOME/.oci/config"
echo "Verifying OCI API key fingerprint..."

# Extract fingerprint from config
CONFIG_FINGERPRINT=$(grep "^fingerprint" "$CONFIG_FILE" | cut -d "=" -f2 | tr -d '[:space:]')
echo "Fingerprint in config: $CONFIG_FINGERPRINT"

# Extract key file path
KEY_FILE=$(grep "^key_file" "$CONFIG_FILE" | cut -d "=" -f2 | tr -d '[:space:]')

# Expand ~ to $HOME if present
if [[ "$KEY_FILE" == "~/"* ]]; then
    KEY_FILE="${KEY_FILE/#\~/$HOME}"
fi

# Check if key file exists
if [ ! -f "$KEY_FILE" ]; then
    echo "ERROR: Key file $KEY_FILE does not exist!"
    exit 1
fi

echo "Computing fingerprint from key file: $KEY_FILE"

# Generate fingerprint from key file
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS version
    GENERATED_FINGERPRINT=$(openssl rsa -pubout -outform DER -in "$KEY_FILE" 2>/dev/null | openssl md5 | awk '{print $2}' | sed 's/\(..\)/\1:/g; s/:$//')
else
    # Linux version
    GENERATED_FINGERPRINT=$(openssl rsa -pubout -outform DER -in "$KEY_FILE" 2>/dev/null | openssl md5 -c | awk '{print $2}')
fi

echo "Generated fingerprint: $GENERATED_FINGERPRINT"

# Compare fingerprints
if [ "$CONFIG_FINGERPRINT" == "$GENERATED_FINGERPRINT" ]; then
    echo "SUCCESS: Fingerprints match!"
else
    echo "ERROR: Fingerprints do not match!"
    echo "This means the key file doesn't correspond to the fingerprint in your OCI config."
    echo ""
    echo "Possible fixes:"
    echo "1. Generate a new key pair:"
    echo "   openssl genrsa -out $KEY_FILE 2048"
    echo "   openssl rsa -pubout -in $KEY_FILE -out ${KEY_FILE}.pub"
    echo ""
    echo "2. Get the new fingerprint:"
    echo "   openssl rsa -pubout -outform DER -in $KEY_FILE | openssl md5 -c"
    echo ""
    echo "3. Update the fingerprint in $CONFIG_FILE"
    echo "4. Upload the public key (${KEY_FILE}.pub) to the OCI Console for your user"
fi
