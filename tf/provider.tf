/**
 * Provider configuration for OCI Kubernetes project
 */

provider "oci" {
  # Use defaults from ~/.oci/config or environment variables
}

# Only configure Kubernetes provider if we know the API is reachable
provider "kubernetes" {
  config_path    = var.kubeconfig_path
  
  # Add increased timeouts to handle API delays
  
  dynamic "exec" {
    for_each = fileexists(var.kubeconfig_path) ? [1] : []
    content {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "kubectl"
      args        = ["config", "view", "--raw", "--minify", "--flatten"]
    }
  }
}

provider "helm" {
  kubernetes {
    config_path    = var.kubeconfig_path
  }
}
