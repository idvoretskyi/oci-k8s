#!/bin/bash

cd "$(dirname "$0")/../tf"

echo "Resetting Terraform provider configuration..."

# Remove existing lock file and .terraform directory
rm -f .terraform.lock.hcl
rm -rf .terraform

# Reinitialize with upgrade to fetch latest providers
echo "Reinitializing Terraform with latest providers..."
terraform init -upgrade

echo "Provider reset complete!"
echo "You can now run 'terraform plan' and 'terraform apply'"
