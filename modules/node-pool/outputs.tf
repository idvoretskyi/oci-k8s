/**
 * Outputs for Node Pool Module
 * Provides comprehensive information about the created node pool resources
 */

#######################
# Core Node Pool Info #
#######################

output "node_pool_id" {
  description = "OCID of the created node pool"
  value       = oci_containerengine_node_pool.node_pool.id
}

output "node_pool_name" {
  description = "Name of the node pool"
  value       = oci_containerengine_node_pool.node_pool.name
}

output "nodes_count" {
  description = "Number of nodes provisioned in the pool"
  value       = var.node_pool_size
}

output "kubernetes_version" {
  description = "Kubernetes version running on the nodes"
  value       = oci_containerengine_node_pool.node_pool.kubernetes_version
}

output "cluster_id" {
  description = "ID of the OKE cluster this node pool belongs to"
  value       = oci_containerengine_node_pool.node_pool.cluster_id
}

output "compartment_id" {
  description = "Compartment ID where the node pool is created"
  value       = oci_containerengine_node_pool.node_pool.compartment_id
}

#######################
# Node Configuration  #
#######################

output "node_shape" {
  description = "Shape of the compute instances in the node pool"
  value       = oci_containerengine_node_pool.node_pool.node_shape
}

output "node_source_details" {
  description = "Details about the node image source"
  value = {
    image_id             = oci_containerengine_node_pool.node_pool.node_source_details[0].image_id
    source_type          = oci_containerengine_node_pool.node_pool.node_source_details[0].source_type
    boot_volume_size_gbs = oci_containerengine_node_pool.node_pool.node_source_details[0].boot_volume_size_in_gbs
  }
}

output "node_config" {
  description = "Node configuration details including placement and size"
  value = {
    size = oci_containerengine_node_pool.node_pool.node_config_details[0].size
    placement_configs = [
      for config in oci_containerengine_node_pool.node_pool.node_config_details[0].placement_configs : {
        availability_domain = config.availability_domain
        subnet_id           = config.subnet_id
      }
    ]
    nsg_ids = oci_containerengine_node_pool.node_pool.node_config_details[0].nsg_ids
  }
}

output "flex_shape_config" {
  description = "Flex shape configuration if applicable"
  value = local.is_flex_shape ? {
    memory_in_gbs = var.memory_in_gbs
    ocpus         = var.ocpus
  } : null
}

#######################
# Node Labels & Taints #
#######################

output "node_labels" {
  description = "Labels applied to the nodes"
  value = [
    for label in oci_containerengine_node_pool.node_pool.initial_node_labels : {
      key   = label.key
      value = label.value
    }
  ]
}

output "node_taints" {
  description = "Taints applied to the nodes"
  value       = var.node_taints
}

#######################
# Scaling Configuration #
#######################

output "autoscaling_config" {
  description = "Autoscaling configuration for the node pool if enabled"
  value = var.enable_autoscaling ? {
    enabled   = true
    min_nodes = var.autoscaling_config.min_nodes
    max_nodes = var.autoscaling_config.max_nodes
    } : {
    enabled   = false
    min_nodes = null
    max_nodes = null
  }
}

output "node_recycling_config" {
  description = "Node recycling configuration if enabled"
  value = var.enable_node_recycling_policy ? {
    enabled  = true
    strategy = var.node_replacement_strategy
    } : {
    enabled = false
  }
}

#######################
# Security Configuration #
#######################

output "security_config" {
  description = "Security configuration for the node pool"
  value = {
    kms_key_id               = var.kms_key_id
    pv_encryption_in_transit = var.enable_pv_encryption_in_transit
    ssh_public_key_provided  = var.ssh_public_key != ""
  }
}

#######################
# Resource Management #
#######################

output "tags" {
  description = "Tags applied to the node pool"
  value       = oci_containerengine_node_pool.node_pool.freeform_tags
}

output "metadata" {
  description = "Metadata about the node pool for use in dependent resources"
  value = {
    node_pool_id       = oci_containerengine_node_pool.node_pool.id
    node_pool_name     = oci_containerengine_node_pool.node_pool.name
    kubernetes_version = oci_containerengine_node_pool.node_pool.kubernetes_version
    node_count         = var.node_pool_size
    node_shape         = oci_containerengine_node_pool.node_pool.node_shape
    os_type            = "${var.os_name}-${var.os_version}"
    autoscaling        = var.enable_autoscaling
  }
}
