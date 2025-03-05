#!/bin/bash

echo "Testing OCI API authentication..."

# Try running an OCI CLI command that requires authentication
echo "Attempting to list OCI regions (requires authentication)..."
if oci iam region list --output table > /dev/null 2>&1; then
    echo "SUCCESS: Authentication successful!"
    echo "Your OCI credentials are valid and working correctly."
    oci iam region list --output table
else
    echo "ERROR: Authentication failed!"
    echo ""
    echo "Full error output:"
    oci iam region list --output table
    
    echo ""
    echo "Common reasons for authentication failure:"
    echo "1. Incorrect fingerprint in ~/.oci/config"
    echo "2. The API key doesn't match the one uploaded to OCI Console"
    echo "3. The user OCID or tenancy OCID is incorrect"
    echo "4. The user account is locked or disabled"
    echo "5. The key file has incorrect permissions"
    
    echo ""
    echo "Run these commands to verify your configuration:"
    echo "chmod +x ./scripts/verify_fingerprint.sh"
    echo "./scripts/verify_fingerprint.sh"
fi
