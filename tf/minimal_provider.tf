/*
# Rename main.tf temporarily and uncomment this file to test with minimal configuration

provider "oci" {}

resource "null_resource" "auth_test" {
  provisioner "local-exec" {
    command = "oci iam region list --output table"
  }
}

output "auth_success" {
  value = "Authentication successful!"
  depends_on = [null_resource.auth_test]
}
*/
