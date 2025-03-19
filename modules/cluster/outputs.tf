/**
 * Outputs for Cluster Module
 */

output "cluster_id" {
  description = "OCID of the created OKE cluster"
  value       = oci_containerengine_cluster.oke_cluster.id
}

output "cluster_name" {
  description = "Name of the OKE cluster"
  value       = oci_containerengine_cluster.oke_cluster.name
}

output "kubernetes_version" {
  description = "Kubernetes version of the cluster"
  value       = oci_containerengine_cluster.oke_cluster.kubernetes_version
}

output "endpoints" {
  description = "Kubernetes API server endpoints"
  value       = oci_containerengine_cluster.oke_cluster.endpoints
  sensitive   = true
}
