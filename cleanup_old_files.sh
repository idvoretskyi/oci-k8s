#!/bin/bash

# Clean up unused files from the repository
echo "Cleaning up old configuration files..."

# Remove authentication test files
rm -f tf/auth_test.tf tf/minimal_provider.tf tf/env_provider.tf

# Organize scripts directory
mkdir -p scripts/utils
if [ -f "scripts/cleanup_resources.sh" ]; then
  mv scripts/cleanup_resources.sh scripts/utils/
fi

# Remove any temporary files
find . -name "*.tmp" -type f -delete
find . -name "*.bak" -type f -delete
find . -name "*~" -type f -delete

echo "Repository cleanup complete!"
