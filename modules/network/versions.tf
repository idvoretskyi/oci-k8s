/**
 * Provider versions for Network Module
 * OpenTofu compatible configuration
 */

terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">=4.100.0"
    }
  }
}
