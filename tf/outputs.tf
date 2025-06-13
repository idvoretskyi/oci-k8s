# ARM OKE Cluster Outputs

output "cluster_id" {
  description = "OCID of the ARM OKE cluster"
  value       = oci_containerengine_cluster.arm_cluster.id
}

output "cluster_name" {
  description = "Name of the ARM OKE cluster"
  value       = oci_containerengine_cluster.arm_cluster.name
}

output "api_endpoint" {
  description = "Kubernetes API endpoint"
  value       = oci_containerengine_cluster.arm_cluster.endpoints[0].kubernetes
  sensitive   = true
}

output "vcn_id" {
  description = "OCID of the VCN"
  value       = oci_core_vcn.vcn.id
}

output "arm_node_pool_id" {
  description = "OCID of the ARM node pool"
  value       = oci_containerengine_node_pool.arm_pool.id
}

output "kubeconfig_command" {
  description = "Command to generate kubeconfig for the ARM cluster"
  value       = "oci ce cluster create-kubeconfig --cluster-id ${oci_containerengine_cluster.arm_cluster.id} --file ~/.kube/config --region ${var.region} --token-version 2.0.0"
}

output "cluster_region" {
  description = "Region where the ARM cluster is deployed"
  value       = var.region
}

output "node_shape" {
  description = "Shape of the ARM nodes"
  value       = "VM.Standard.A1.Flex"
}

output "architecture" {
  description = "CPU architecture of the cluster"
  value       = "arm64"
}