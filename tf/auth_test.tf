/*
# Minimal provider configuration for authentication testing
# Uncomment this and comment out the existing provider block in main.tf

provider "oci" {
  # Empty provider block will use ~/.oci/config
}

# Simple authentication test that only runs the auth_test
# Run with: terraform init && terraform apply -target=null_resource.auth_test
resource "null_resource" "auth_test" {
  triggers = {
    always_run = timestamp()
  }
  
  provisioner "local-exec" {
    command = "echo Testing OCI authentication... && oci iam region list --output table"
  }
}

output "auth_test" {
  value = "If you can see this output without errors, authentication is working!"
}
*/
