/**
 * Provider configuration for OCI Kubernetes project
 */

provider "oci" {
  # Use defaults from ~/.oci/config or environment variables
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}
