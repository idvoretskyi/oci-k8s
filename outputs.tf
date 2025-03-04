output "vcn_id" {
  description = "The OCID of the VCN"
  value       = oci_core_virtual_network.vcn.id
}

output "oke_cluster_id" {
  description = "The OCID of the OCI Kubernetes Cluster"
  value       = oci_containerengine_cluster.oke_cluster.id
}
