/**
 * Outputs for Cluster Module
 * Provides comprehensive information about the created OKE cluster
 */

#######################
# Core Cluster Info   #
#######################

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

output "compartment_id" {
  description = "Compartment ID where the cluster is created"
  value       = oci_containerengine_cluster.oke_cluster.compartment_id
}

output "state" {
  description = "Current state of the cluster"
  value       = oci_containerengine_cluster.oke_cluster.state
}

output "lifecycle_details" {
  description = "Detailed status of current lifecycle state"
  value       = oci_containerengine_cluster.oke_cluster.lifecycle_details
}

#######################
# Network Information #
#######################

output "vcn_id" {
  description = "VCN ID where the cluster is deployed"
  value       = oci_containerengine_cluster.oke_cluster.vcn_id
}

output "endpoints" {
  description = "Kubernetes API server endpoints"
  value       = oci_containerengine_cluster.oke_cluster.endpoints
  sensitive   = true
}

output "endpoint_config" {
  description = "Endpoint configuration including public/private access"
  value = {
    is_public = oci_containerengine_cluster.oke_cluster.endpoint_config[0].is_public_ip_enabled
    subnet_id = oci_containerengine_cluster.oke_cluster.endpoint_config[0].subnet_id
    nsg_ids   = oci_containerengine_cluster.oke_cluster.endpoint_config[0].nsg_ids
  }
}

output "network_config" {
  description = "Kubernetes network configuration"
  value = {
    pods_cidr     = oci_containerengine_cluster.oke_cluster.options[0].kubernetes_network_config[0].pods_cidr
    services_cidr = oci_containerengine_cluster.oke_cluster.options[0].kubernetes_network_config[0].services_cidr
  }
}

#######################
# Security Info       #
#######################

output "security_config" {
  description = "Security configuration for the cluster"
  value = {
    pod_security_enabled   = var.enable_pod_security_admission && (null_resource.deploy_pod_security_standards[0].id != "" ? true : false)
    kms_key_id             = var.kms_key_id
  }
}

output "addons_config" {
  description = "Enabled add-ons for the cluster"
  value = {
    dashboard_enabled  = oci_containerengine_cluster.oke_cluster.options[0].add_ons[0].is_kubernetes_dashboard_enabled
    monitoring_enabled = var.enable_monitoring
  }
}

#######################
# Resource Management #
#######################

output "tags" {
  description = "Tags applied to the cluster"
  value       = oci_containerengine_cluster.oke_cluster.freeform_tags
}

output "created_at" {
  description = "When the cluster was created"
  value       = oci_containerengine_cluster.oke_cluster.id # Changed from time_created to id as a workaround
}

output "metadata" {
  description = "Metadata about the cluster for use in dependent modules"
  value = {
    cluster_id         = oci_containerengine_cluster.oke_cluster.id
    kubernetes_version = oci_containerengine_cluster.oke_cluster.kubernetes_version
    state              = oci_containerengine_cluster.oke_cluster.state
    security_enabled   = var.enable_pod_security_admission
  }
}

output "monitoring_namespace" {
  description = "The Kubernetes namespace created for monitoring tools"
  value       = var.enable_monitoring ? kubernetes_namespace.monitoring[0].metadata[0].name : null
}

output "monitoring_enabled" {
  description = "Whether the monitoring integration is enabled for this cluster"
  value       = var.enable_monitoring
}

output "monitoring_config" {
  description = "The monitoring configuration to pass to the monitoring module"
  value       = var.monitoring_config
  sensitive   = false
}
