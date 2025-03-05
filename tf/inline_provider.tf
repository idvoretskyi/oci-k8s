# Comment out the original provider block in main.tf before using this file

/*
provider "oci" {
  region           = var.region
  tenancy_ocid     = var.compartment_id
  user_ocid        = var.user_ocid == null ? data.external.oci_config.result.user_ocid : var.user_ocid
  fingerprint      = var.fingerprint == null ? data.external.oci_config.result.fingerprint : var.fingerprint
  private_key      = file(var.private_key_path)
}

# Extract config values using local-exec
data "external" "oci_config" {
  program = ["bash", "${path.module}/extract_oci_config.sh"]
}
*/
