output "vcn_id" {
  description = "The OCID of the VCN"
  value       = oci_core_virtual_network.vcn.id
}

output "oke_cluster_id" {
  description = "The OCID of the OCI Kubernetes Cluster"
  value       = oci_containerengine_cluster.oke_cluster.id
}

output "cluster_id" {
  description = "OCID of the created OKE cluster"
  value       = oci_containerengine_cluster.oke_cluster.id
}

output "cluster_name" {
  description = "Name of the created OKE cluster"
  value       = oci_containerengine_cluster.oke_cluster.name
}

output "kubernetes_endpoint" {
  description = "The endpoint for the Kubernetes API server"
  value       = oci_containerengine_cluster.oke_cluster.endpoints[0].public_endpoint
}

output "node_pool_id" {
  description = "OCID of the created node pool"
  value       = oci_containerengine_node_pool.node_pool.id
}

output "subnet_id" {
  description = "OCID of the created subnet"
  value       = oci_core_subnet.subnet.id
}

output "get_kubeconfig_command" {
  description = "Command to get the kubeconfig file"
  value       = "oci ce cluster create-kubeconfig --cluster-id ${oci_containerengine_cluster.oke_cluster.id} --file ~/.kube/config --region ${var.region} --token-version 2.0.0"
}
