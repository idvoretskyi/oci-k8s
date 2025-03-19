#!/bin/bash

echo "Fixing OCI provider source references..."

# Find all Terraform files
TF_FILES=$(find /Users/idv/GitHub/idvoretskyi/terraform-oci-k8s -name "*.tf")

# Replace hashicorp/oci with oracle/oci in all Terraform files
for FILE in $TF_FILES; do
  echo "Checking $FILE"
  if grep -q "hashicorp/oci" "$FILE"; then
    echo "Updating provider source in $FILE"
    sed -i '' 's/hashicorp\/oci/oracle\/oci/g' "$FILE"
  fi
done

# Check for any remaining references to the old provider
REMAINING=$(grep -r "hashicorp/oci" --include="*.tf" /Users/idv/GitHub/idvoretskyi/terraform-oci-k8s)
if [ -n "$REMAINING" ]; then
  echo "Warning: Still found references to hashicorp/oci in:"
  echo "$REMAINING"
else
  echo "All references to hashicorp/oci have been updated to oracle/oci."
fi

echo "Provider source fix complete. Run 'terraform init -upgrade' to update providers."
