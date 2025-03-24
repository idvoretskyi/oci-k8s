# Utility Scripts

This directory contains utility scripts to help with OCI Kubernetes cluster management.

## Available Scripts

### Resource Cleanup

`utils/cleanup_resources.sh` - Helps clean up resources when OpenTofu destroy encounters dependency issues

#### Usage

```bash
./utils/cleanup_resources.sh <subnet-ocid>
```

This script:
1. Lists resources attached to a subnet
2. Provides guidance on manually removing these resources
3. Helps troubleshoot dependency issues during destroy operations

## Adding New Scripts

When adding new scripts:
1. Add them to the appropriate subdirectory
2. Make sure they have proper execution permissions (`chmod +x`)
3. Include documentation in the script header
4. Update this README with usage information
