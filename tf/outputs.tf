/**
 * Terraform outputs for the OCI Kubernetes deployment
 */

output "vcn_id" {
  description = "The OCID of the created VCN"
  value       = module.network.vcn_id
}

output "oke_cluster_id" {
  description = "The OCID of the OCI Kubernetes Cluster"
  value       = module.cluster.cluster_id
}

output "cluster_id" {
  description = "The OCID of the created Kubernetes cluster"
  value       = module.cluster.cluster_id
}

output "cluster_name" {
  description = "The name of the created Kubernetes cluster"
  value       = module.cluster.cluster_name
}

output "kubernetes_version" {
  description = "The version of Kubernetes running on the cluster"
  value       = module.cluster.kubernetes_version
}

output "endpoints" {
  description = "The endpoints for the Kubernetes API server"
  value       = module.cluster.endpoints
  sensitive   = true
}

output "node_pool_id" {
  description = "The OCID of the created node pool"
  value       = module.node_pool.node_pool_id
}

output "node_count" {
  description = "Number of worker nodes in the cluster"
  value       = module.node_pool.nodes_count
}

output "service_subnet_id" {
  description = "OCID of the service subnet"
  value       = module.network.service_subnet_id
}

output "worker_subnet_id" {
  description = "OCID of the worker subnet"
  value       = module.network.worker_subnet_id
}

output "get_kubeconfig_command" {
  description = "Command to get the kubeconfig file"
  value       = "oci ce cluster create-kubeconfig --cluster-id ${module.cluster.cluster_id} --file ~/.kube/config --region ${var.region} --token-version 2.0.0"
}

# Monitoring outputs
output "monitoring_info" {
  description = "Monitoring service information"
  value = var.enable_monitoring ? {
    namespace      = module.monitoring[0].monitoring_namespace
    prometheus_svc = module.monitoring[0].prometheus_service
    grafana_svc    = module.monitoring[0].grafana_service
    alert_svc      = module.monitoring[0].alertmanager_service
  } : null
  sensitive = true
}

output "grafana_admin_info" {
  description = "Grafana admin credentials"
  value = var.enable_monitoring ? {
    username = "admin"
    password = var.grafana_admin_password
  } : null
  sensitive = true
}

output "monitoring_enabled" {
  description = "Whether monitoring is enabled"
  value       = var.enable_monitoring
}
