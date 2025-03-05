# This file contains local key configuration for debugging purposes

data "local_file" "oci_private_key" {
  filename = var.private_key_path
}

output "key_exists" {
  value = fileexists(var.private_key_path) ? "Private key file exists" : "Private key file does not exist"
}

output "key_path" {
  value = var.private_key_path
}
