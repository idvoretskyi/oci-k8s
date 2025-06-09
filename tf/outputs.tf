output "cluster_id" {
  value = oci_containerengine_cluster.cluster.id
}

output "cluster_name" {
  value = oci_containerengine_cluster.cluster.name
}

output "vcn_id" {
  value = oci_core_vcn.vcn.id
}

output "api_endpoint" {
  value     = oci_containerengine_cluster.cluster.endpoints[0].kubernetes
  sensitive = true
}

output "node_pool_id" {
  value = oci_containerengine_node_pool.pool.id
}

output "kubeconfig_command" {
  value = "oci ce cluster create-kubeconfig --cluster-id ${oci_containerengine_cluster.cluster.id} --file ~/.kube/config --region ${var.region} --token-version 2.0.0"
}