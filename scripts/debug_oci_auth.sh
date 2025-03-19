#!/bin/bash

CONFIG_FILE="$HOME/.oci/config"
echo "=========================================="
echo "OCI Authentication Debugging"
echo "=========================================="

# 1. Check if OCI CLI is installed
if ! command -v oci &> /dev/null; then
    echo "ERROR: OCI CLI is not installed!"
    echo "Please install it first: bash -c \"\$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)\""
    exit 1
fi

echo "OCI CLI is installed."

# 2. Check config file
if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Config file doesn't exist at $CONFIG_FILE"
    exit 1
fi

echo -e "\n--- Config file contents ---"
cat "$CONFIG_FILE" | grep -v "ocid1"
echo "--- End of visible config ---"

# 3. Extract values from config
USER_OCID=$(grep "^user" "$CONFIG_FILE" | cut -d "=" -f2 | tr -d '[:space:]')
FINGERPRINT=$(grep "^fingerprint" "$CONFIG_FILE" | cut -d "=" -f2 | tr -d '[:space:]')
TENANCY_OCID=$(grep "^tenancy" "$CONFIG_FILE" | cut -d "=" -f2 | tr -d '[:space:]')
REGION=$(grep "^region" "$CONFIG_FILE" | cut -d "=" -f2 | tr -d '[:space:]')
KEY_FILE=$(grep "^key_file" "$CONFIG_FILE" | cut -d "=" -f2 | tr -d '[:space:]')

# Expand ~ to $HOME if present
if [[ "$KEY_FILE" == "~/"* ]]; then
    KEY_FILE="${KEY_FILE/#\~/$HOME}"
fi

echo -e "\n--- Config values ---"
echo "User OCID: ${USER_OCID:0:10}... (truncated)"
echo "Tenancy OCID: ${TENANCY_OCID:0:10}... (truncated)"
echo "Fingerprint: $FINGERPRINT"
echo "Region: $REGION"
echo "Key file: $KEY_FILE"

# 4. Check key file
if [ ! -f "$KEY_FILE" ]; then
    echo "ERROR: Key file doesn't exist at $KEY_FILE"
    exit 1
fi

# 5. Check key permissions
if [[ "$OSTYPE" == "darwin"* ]]; then
    PERMS=$(stat -f %Lp "$KEY_FILE")
else
    PERMS=$(stat -c %a "$KEY_FILE")
fi

echo -e "\n--- Key file checks ---"
echo "Key file permissions: $PERMS (should be 600)"
echo "Key file size: $(wc -c < "$KEY_FILE") bytes"
echo "Has OCI_API_KEY label: $(grep -q "OCI_API_KEY" "$KEY_FILE" && echo "YES" || echo "NO")"

# 6. Verify key format
echo -e "\n--- Testing key validity ---"
if openssl rsa -in "$KEY_FILE" -check -noout 2>/dev/null; then
    echo "Key is valid RSA format"
else
    echo "ERROR: Key is not valid RSA format"
fi

# 7. Calculate fingerprint from key
echo -e "\n--- Fingerprint verification ---"
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS version
    GENERATED_FINGERPRINT=$(openssl rsa -pubout -outform DER -in "$KEY_FILE" 2>/dev/null | openssl md5 | awk '{print $2}' | sed 's/\(..\)/\1:/g; s/:$//')
else
    # Linux version
    GENERATED_FINGERPRINT=$(openssl rsa -pubout -outform DER -in "$KEY_FILE" 2>/dev/null | openssl md5 -c | awk '{print $2}')
fi

echo "Config fingerprint : $FINGERPRINT"
echo "Generated fingerprint: $GENERATED_FINGERPRINT"

if [ "$FINGERPRINT" == "$GENERATED_FINGERPRINT" ]; then
    echo "✅ Fingerprints match!"
else
    echo "❌ Fingerprints do not match!"
fi

# 8. Try to run OCI CLI with debug output
echo -e "\n--- Trying OCI CLI with debug output ---"
echo "Running: OCI_DEBUG=1 oci iam region list"
OCI_DEBUG=1 SUPPRESS_LABEL_WARNING=True oci iam region list 2>&1 | head -30

echo -e "\n--- Try these fixes ---"
echo "1. Ensure your key is properly uploaded to OCI console:"
echo "   - Login to OCI Console"
echo "   - Go to Profile -> User Settings -> API Keys"
echo "   - Verify the fingerprint matches: $FINGERPRINT"

echo -e "\n2. Try with environment variables:"
echo "   export OCI_CLI_USER=\"$USER_OCID\""
echo "   export OCI_CLI_TENANCY=\"$TENANCY_OCID\""
echo "   export OCI_CLI_FINGERPRINT=\"$FINGERPRINT\""
echo "   export OCI_CLI_KEY_FILE=\"$KEY_FILE\""
echo "   export OCI_CLI_REGION=\"$REGION\""
echo "   export SUPPRESS_LABEL_WARNING=True"
echo "   oci iam region list"

echo -e "\n3. Regenerate keys with proper format:"
echo "   ./scripts/regenerate_keys_with_label.sh"
