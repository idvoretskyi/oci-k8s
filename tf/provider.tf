/**
 * Provider configuration for OCI Kubernetes project
 * Configured with robust authentication handling
 */

# Oracle Cloud Infrastructure provider
provider "oci" {
  # Use defaults from ~/.oci/config or environment variables
  # Can be overridden using variables in variables.tf
  region           = var.region
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
}

# Kubernetes provider for managing k8s resources
provider "kubernetes" {
  config_path = var.kubeconfig_path

  # Handle case where kubeconfig doesn't exist yet during initial apply
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubectl"
    args        = ["config", "view", "--raw", "--minify", "--flatten"]
  }
}
