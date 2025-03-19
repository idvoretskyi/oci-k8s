#!/bin/bash

# Master script for OCI setup and authentication

source "$(dirname "$0")/utils/auth.sh"

function show_help() {
  echo "Usage: setup-oci.sh [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --verify      Verify OCI configuration"
  echo "  --env         Set environment variables"
  echo "  --test        Test authentication"
  echo "  --generate    Generate new API keys"
  echo "  --help        Show this help message"
  echo ""
  echo "If no options are provided, --verify, --env, and --test will be used."
}

# Parse command line arguments
VERIFY=0
ENV=0
TEST=0
GENERATE=0

if [ $# -eq 0 ]; then
  VERIFY=1
  ENV=1
  TEST=1
else
  while [ $# -gt 0 ]; do
    case "$1" in
      --verify)
        VERIFY=1
        ;;
      --env)
        ENV=1
        ;;
      --test)
        TEST=1
        ;;
      --generate)
        GENERATE=1
        ;;
      --help)
        show_help
        exit 0
        ;;
      *)
        echo "Unknown option: $1"
        show_help
        exit 1
        ;;
    esac
    shift
  done
fi

# Run the selected actions
if [ $GENERATE -eq 1 ]; then
  generate_keys
fi

if [ $VERIFY -eq 1 ]; then
  verify_config
  if [ $? -ne 0 ]; then
    echo "Configuration verification failed."
    exit 1
  fi
fi

if [ $ENV -eq 1 ]; then
  set_env_variables
fi

if [ $TEST -eq 1 ]; then
  test_auth
  if [ $? -ne 0 ]; then
    echo "Authentication test failed."
    exit 1
  else
    echo "Authentication test passed."
  fi
fi

echo "OCI setup completed successfully."
