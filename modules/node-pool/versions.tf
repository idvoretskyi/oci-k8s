/**
 * Provider versions for Node Pool Module
 */

terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">=4.100.0"
    }
  }
}
