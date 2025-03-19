/*
# Alternative provider configuration that uses environment variables
# Uncomment this and comment out the provider in main.tf to use

provider "oci" {
  # This empty provider will use environment variables or the OCI config file
  # with the addition of the environment variable to suppress the key label warning
}

# Set the environment variables - keep this commented, for reference only
# export SUPPRESS_LABEL_WARNING=True
# export OCI_CLI_FINGERPRINT="your_fingerprint"
# export OCI_CLI_TENANCY="your_tenancy_ocid"
# export OCI_CLI_USER="your_user_ocid"
# export OCI_CLI_REGION="your_region"
# export OCI_CLI_KEY_FILE="your_key_file_path"
*/
