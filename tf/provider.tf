provider "oci" {
  region           = var.region
  tenancy_ocid     = coalesce(var.tenancy_ocid, local.tenancy_ocid)
  user_ocid        = coalesce(var.user_ocid, local.user_ocid)
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
}

terraform {
  required_providers {
    oci = {
      source  = "registry.opentofu.org/oracle/oci"
      version = ">= 7.0.0"
    }
  }
  required_version = ">= 1.5.0"
}
