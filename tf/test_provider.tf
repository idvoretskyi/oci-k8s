/*
# Test provider configuration - uncomment and comment out the provider in main.tf
provider "oci" {
  auth = "InstancePrincipal"
}
*/

# Simple data source to test API connectivity
data "oci_identity_regions" "regions" {
  # This data source doesn't depend on any variables
  # It will attempt to list all available OCI regions
}

output "regions" {
  value = length(data.oci_identity_regions.regions.regions) > 0 ? "Successfully connected to OCI API" : "Failed to connect to OCI API"
}
