# Minimal test configuration to isolate authentication issues
# Run this separately: terraform init -reconfigure && terraform apply -target=output.oci_config_test

output "oci_config_test" {
  value = "Running OCI configuration test..."
  
  # This triggers the local-exec
  depends_on = [null_resource.oci_config_test]
}

resource "null_resource" "oci_config_test" {
  # This forces the resource to be recreated each time
  triggers = {
    always_run = timestamp()
  }
  
  provisioner "local-exec" {
    command = "oci iam region list --output table"
  }
}
