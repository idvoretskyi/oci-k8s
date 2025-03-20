/**
 * Outputs for Network Module
 */

output "vcn_id" {
  description = "The OCID of the created VCN"
  value       = oci_core_virtual_network.vcn.id
}

output "service_subnet_id" {
  description = "The OCID of the service subnet for Kubernetes API"
  value       = oci_core_subnet.service_subnet.id
}

output "worker_subnet_id" {
  description = "The OCID of the worker subnet for Kubernetes nodes"
  value       = oci_core_subnet.worker_subnet.id
}

output "security_list_id" {
  description = "The OCID of the security list"
  value       = oci_core_security_list.security_list.id
}

output "subnet_dependency" {
  description = "Reference to the subnet dependency waiter"
  value       = null_resource.subnet_dependency_waiter
}
