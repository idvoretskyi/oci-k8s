/**
 * Provider versions for the OCI Kubernetes project
 */

terraform {
  required_version = ">= 0.13.0"
  
  required_providers {
    oci = {
      source  = "oracle/oci"
      # No specific version constraint to avoid checksum issues
    }
    
    kubernetes = {
      source  = "hashicorp/kubernetes"
      # No specific version constraint to avoid checksum issues
    }
    
    helm = {
      source  = "hashicorp/helm"
      # No specific version constraint to avoid checksum issues
    }
  }
}
