#!/bin/bash

CONFIG_FILE="$HOME/.oci/config"
echo "Verifying OCI config file at $CONFIG_FILE"

# List of required keys
REQUIRED_KEYS=("user" "fingerprint" "key_file" "tenancy" "region")

# Check if file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Config file doesn't exist at $CONFIG_FILE"
    exit 1
fi

# Check if DEFAULT profile exists
if ! grep -q "\[DEFAULT\]" "$CONFIG_FILE"; then
    echo "ERROR: No [DEFAULT] profile found in config file"
    exit 1
fi

# Check for each required key
MISSING_KEYS=()
for KEY in "${REQUIRED_KEYS[@]}"; do
    if ! grep -q "^$KEY\s*=" "$CONFIG_FILE"; then
        MISSING_KEYS+=("$KEY")
    fi
done

if [ ${#MISSING_KEYS[@]} -ne 0 ]; then
    echo "ERROR: The following required keys are missing from your config:"
    for KEY in "${MISSING_KEYS[@]}"; do
        echo "  - $KEY"
    done
    exit 1
fi

# Extract key file path
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

# Check key permissions
if [[ "$OSTYPE" == "darwin"* ]]; then
    PERMS=$(stat -f %Lp "$KEY_FILE")
else
    PERMS=$(stat -c %a "$KEY_FILE")
fi

if [ "$PERMS" != "600" ]; then
    echo "WARNING: Key file permissions are $PERMS (should be 600)"
    echo "Run: chmod 600 \"$KEY_FILE\""
fi

# All checks passed
echo "SUCCESS: Your OCI configuration appears to be complete and correct."
echo "Configuration values found:"

echo "  user=$(grep "^user" "$CONFIG_FILE" | cut -d "=" -f2 | tr -d '[:space:]')"
echo "  fingerprint=$(grep "^fingerprint" "$CONFIG_FILE" | cut -d "=" -f2 | tr -d '[:space:]')"
echo "  key_file=$KEY_FILE"
echo "  tenancy=$(grep "^tenancy" "$CONFIG_FILE" | cut -d "=" -f2 | tr -d '[:space:]')"
echo "  region=$(grep "^region" "$CONFIG_FILE" | cut -d "=" -f2 | tr -d '[:space:]')"

# Test key file
echo ""
echo "Testing private key..."
if openssl rsa -in "$KEY_FILE" -noout &>/dev/null; then
    echo "SUCCESS: Key file is valid and readable"
else
    echo "ERROR: Key file is not a valid private key or cannot be read"
    exit 1
fi
