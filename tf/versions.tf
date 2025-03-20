/**
 * Provider versions for the OCI Kubernetes project with OpenTofu
 */

terraform {  # This syntax works with both OpenTofu and Terraform
  required_version = ">= 1.5.0"  # Compatible with OpenTofu 1.6.0+
  
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
