#!/bin/bash

# This script helps clean up resources when Terraform/OpenTofu destroy encounters dependency issues

echo "Starting OCI resource cleanup helper..."

# Check if subnet ID is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <subnet-ocid>"
  exit 1
fi

SUBNET_ID=$1

# List and show resources that might be blocking subnet deletion
echo "Checking for resources attached to subnet $SUBNET_ID..."
oci network vnic list --subnet-id $SUBNET_ID --all

echo "You may need to manually delete these resources before proceeding with terraform destroy"
echo "For example, you might need to:"
echo "1. Delete any load balancers in this subnet"
echo "2. Terminate instances in this subnet"
echo "3. Remove any service gateways"
echo "4. Wait for asynchronous OCI operations to complete"

echo "After cleaning up resources, try running terraform destroy again"
