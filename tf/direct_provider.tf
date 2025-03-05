# Comment out the provider in main.tf and uncomment this when ready to use
/*
provider "oci" {
  # Keep these values from variables
  region       = var.region
  tenancy_ocid = var.compartment_id
  
  # Get these values directly from the OCI config file if not specified in variables
  user_ocid   = var.user_ocid != null ? var.user_ocid : local.config_values.user_ocid
  fingerprint = var.fingerprint != null ? var.fingerprint : local.config_values.fingerprint
  
  # Direct inclusion of private key content
  private_key = file(var.private_key_path)
}

locals {
  # Read OCI config values
  config_file = file("~/.oci/config")
  
  # Extract values using regex
  config_values = {
    user_ocid   = regex("user\\s*=\\s*([^\\s]+)", local.config_file)[0]
    fingerprint = regex("fingerprint\\s*=\\s*([^\\s]+)", local.config_file)[0]
  }
}
*/
