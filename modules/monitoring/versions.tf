/**
 * Provider versions for Monitoring Module
 * OpenTofu compatible configuration
 */

terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">=4.100.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">=2.10.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">=2.5.0"
    }
  }
}
