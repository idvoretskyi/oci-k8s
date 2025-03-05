#!/bin/bash

CONFIG_DIR="$HOME/.oci"
CONFIG_FILE="$CONFIG_DIR/config"
KEY_FILE="$CONFIG_DIR/oci_api_key.pem"

echo "Checking OCI configuration..."

# Check if we're on macOS or Linux for stat command differences
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  STAT_PERM_CMD="stat -f %Lp"
else
  # Linux and others
  STAT_PERM_CMD="stat -c %a"
fi

# Check if config directory exists
if [ ! -d "$CONFIG_DIR" ]; then
  echo "Config directory $CONFIG_DIR does not exist. Creating it..."
  mkdir -p "$CONFIG_DIR"
  chmod 700 "$CONFIG_DIR"
fi

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Config file $CONFIG_FILE does not exist!"
  echo "Please run 'oci setup config' to create a configuration file."
  exit 1
else
  echo "Config file exists at $CONFIG_FILE"
  
  # Check if DEFAULT profile exists
  if grep -q "\[DEFAULT\]" "$CONFIG_FILE"; then
    echo "DEFAULT profile found in config file."
  else
    echo "DEFAULT profile not found in config file!"
    echo "Please ensure your config file has a [DEFAULT] section."
    cat "$CONFIG_FILE"
    exit 1
  fi
  
  # Extract key_file path from config
  CONFIG_KEY_FILE=$(grep "^key_file" "$CONFIG_FILE" | cut -d "=" -f2 | tr -d '[:space:]')
  
  if [ -z "$CONFIG_KEY_FILE" ]; then
    echo "No key_file specified in config!"
    exit 1
  else
    echo "Key file specified in config: $CONFIG_KEY_FILE"
    
    # Expand ~ to $HOME
    if [[ "$CONFIG_KEY_FILE" == "~/"* ]]; then
      CONFIG_KEY_FILE="${CONFIG_KEY_FILE/#\~/$HOME}"
      echo "Expanded key path: $CONFIG_KEY_FILE"
    fi
    
    # Check if key file exists
    if [ ! -f "$CONFIG_KEY_FILE" ]; then
      echo "Key file $CONFIG_KEY_FILE does not exist!"
      
      # Offer to generate new keys
      read -p "Do you want to generate a new key pair? (y/n): " GENERATE_KEYS
      if [[ "$GENERATE_KEYS" == "y" ]]; then
        echo "Generating new key pair..."
        openssl genrsa -out "$CONFIG_KEY_FILE" 2048
        chmod 600 "$CONFIG_KEY_FILE"
        
        # Generate public key
        PUBLIC_KEY="${CONFIG_KEY_FILE}.pub"
        openssl rsa -pubout -in "$CONFIG_KEY_FILE" -out "$PUBLIC_KEY"
        
        # Display fingerprint
        echo "Key fingerprint (add this to your OCI console):"
        openssl rsa -pubout -outform DER -in "$CONFIG_KEY_FILE" | openssl md5 -c
        
        echo "Public key (upload this to OCI console):"
        cat "$PUBLIC_KEY"
      fi
      exit 1
    else
      echo "Key file exists at $CONFIG_KEY_FILE"
      
      # Check permissions using OS-appropriate stat command
      KEY_PERMS=$(eval "$STAT_PERM_CMD \"$CONFIG_KEY_FILE\"")
      if [ "$KEY_PERMS" != "600" ]; then
        echo "Warning: Key file permissions are $KEY_PERMS (should be 600)"
        read -p "Fix permissions now? (y/n): " FIX_PERMS
        if [[ "$FIX_PERMS" == "y" ]]; then
          chmod 600 "$CONFIG_KEY_FILE"
          echo "Permissions fixed."
        fi
      else
        echo "Key file permissions are correct (600)"
      fi
    fi
  fi
fi

echo "OCI configuration check complete."
