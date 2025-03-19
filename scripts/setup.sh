#!/bin/bash
# Main setup script for OCI Kubernetes project

source "$(dirname "$0")/utils/oci_auth.sh"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --check)
      CHECK=true
      shift
      ;;
    --env)
      ENV=true
      shift
      ;;
    --test)
      TEST=true
      shift
      ;;
    *)
      echo "Unknown option: $key"
      echo "Valid options: --check, --env, --test"
      exit 1
      ;;
  esac
done

# Default: Run all steps if none specified
if [[ -z "$CHECK" && -z "$ENV" && -z "$TEST" ]]; then
  CHECK=true
  ENV=true
  TEST=true
fi

# Check OCI configuration
if [[ "$CHECK" == "true" ]]; then
  check_oci_config
fi

# Set environment variables
if [[ "$ENV" == "true" ]]; then
  setup_env_vars
fi

# Test authentication
if [[ "$TEST" == "true" ]]; then
  test_auth
fi

echo "Setup complete. You can now run: cd tf && terraform init && terraform apply"
