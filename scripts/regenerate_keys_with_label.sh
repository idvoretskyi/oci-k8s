#!/bin/bash

CONFIG_DIR="$HOME/.oci"
CONFIG_FILE="$CONFIG_DIR/config"
KEY_FILE="$CONFIG_DIR/oci_api_key.pem"
PUBLIC_KEY_FILE="$CONFIG_DIR/oci_api_key_public.pem"

echo "=============================================================="
echo "OCI API Key Regeneration with OCI_API_KEY Label"
echo "=============================================================="

# Ensure OCI config directory exists
if [ ! -d "$CONFIG_DIR" ]; then
  echo "Creating OCI configuration directory at $CONFIG_DIR"
  mkdir -p "$CONFIG_DIR"
  chmod 700 "$CONFIG_DIR"
fi

# Backup existing config if it exists
if [ -f "$CONFIG_FILE" ]; then
  BACKUP_FILE="$CONFIG_FILE.$(date +%Y%m%d%H%M%S).backup"
  echo "Backing up existing config to $BACKUP_FILE"
  cp "$CONFIG_FILE" "$BACKUP_FILE"
fi

# Backup existing key if it exists
if [ -f "$KEY_FILE" ]; then
  KEY_BACKUP="$KEY_FILE.$(date +%Y%m%d%H%M%S).backup"
  echo "Backing up existing private key to $KEY_BACKUP"
  cp "$KEY_FILE" "$KEY_BACKUP"
fi

# Generate new API key pair
echo "Generating new API key pair..."
openssl genrsa -out "$KEY_FILE" 2048
chmod 600 "$KEY_FILE"

# Add the OCI_API_KEY label
echo "Adding OCI_API_KEY label..."
echo "" >> "$KEY_FILE"  # Ensure there's a newline
echo "OCI_API_KEY" >> "$KEY_FILE"

# Generate public key
echo "Generating public key..."
openssl rsa -pubout -in "$KEY_FILE" -out "$PUBLIC_KEY_FILE"

# Generate key fingerprint
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS version
  FINGERPRINT=$(openssl rsa -pubout -outform DER -in "$KEY_FILE" 2>/dev/null | openssl md5 | awk '{print $2}' | sed 's/\(..\)/\1:/g; s/:$//')
else
  # Linux version
  FINGERPRINT=$(openssl rsa -pubout -outform DER -in "$KEY_FILE" 2>/dev/null | openssl md5 -c | awk '{print $2}')
fi

echo ""
echo "New key pair generated:"
echo "  - Private key: $KEY_FILE"
echo "  - Public key: $PUBLIC_KEY_FILE"
echo "  - Fingerprint: $FINGERPRINT"

# Get user and tenancy OCIDs
echo ""
echo "Please provide the following information from your OCI Console:"
echo "(You can find these values in the OCI Console under Profile -> User Settings)"
echo ""

read -p "User OCID: " USER_OCID
read -p "Tenancy OCID: " TENANCY_OCID
read -p "Region (e.g., uk-london-1): " REGION

# Write new config
echo "Updating OCI configuration at $CONFIG_FILE"
cat > "$CONFIG_FILE" << EOF
[DEFAULT]
user=$USER_OCID
fingerprint=$FINGERPRINT
key_file=$KEY_FILE
tenancy=$TENANCY_OCID
region=$REGION
EOF

# Display next steps
echo ""
echo "============================"
echo "Configuration Update Complete"
echo "============================"
echo ""
echo "IMPORTANT: You must upload the public key to the OCI Console:"
echo ""
echo "1. Log in to the OCI Console at https://cloud.oracle.com/"
echo "2. Click on the Profile icon (top right) and select 'User Settings'"
echo "3. Under 'Resources', click on 'API Keys'"
echo "4. Click 'Add API Key'"
echo "5. Select 'Paste Public Key' and paste the contents of the public key below"
echo "6. Click 'Add'"
echo ""
echo "Here is your public key to copy:"
echo "----------------------------------------"
cat "$PUBLIC_KEY_FILE"
echo "----------------------------------------"
echo ""
echo "After uploading the key, test your configuration with:"
echo "  export SUPPRESS_LABEL_WARNING=True"
echo "  oci iam region list"
echo ""
echo "Then try Terraform again:"
echo "  cd tf && terraform init && terraform apply"
