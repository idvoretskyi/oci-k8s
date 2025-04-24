/**
 * Provider versions for the OCI Kubernetes project with OpenTofu
 * Defining specific version constraints for better stability and predictability
 */

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    # Oracle Cloud Infrastructure provider
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0.0"
    }

    # Kubernetes provider for cluster resource management
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.23.0"
    }

    # Helm provider for deploying charts (monitoring stack)
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.11.0"
    }

    # External provider for local commands
    external = {
      source  = "hashicorp/external"
      version = ">= 2.3.1"
    }

    # Null provider for dependencies and provisioners
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.1"
    }
  }
}
