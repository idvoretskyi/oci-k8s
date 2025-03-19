/**
 * Node Pool Module for OCI Kubernetes
 * 
 * This module creates a node pool in an OKE cluster with the specified configuration
 */

// Fetch the first availability domain for the region if not specified
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

// Fetch compatible images for the specified shape if not directly specified
data "oci_core_images" "compatible_images" {
  compartment_id           = var.compartment_id
  operating_system         = var.os_name
  operating_system_version = var.os_version
  shape                    = var.node_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

// Create Node Pool
resource "oci_containerengine_node_pool" "node_pool" {
  compartment_id     = var.compartment_id
  cluster_id         = var.cluster_id
  kubernetes_version = var.kubernetes_version
  name               = var.node_pool_name
  node_shape         = var.node_shape
  
  node_source_details {
    # Use specified image or latest compatible image
    image_id    = var.node_image_id != null ? var.node_image_id : data.oci_core_images.compatible_images.images[0].id
    source_type = "IMAGE"
  }
  
  node_config_details {
    placement_configs {
      availability_domain = var.availability_domain != null ? var.availability_domain : data.oci_identity_availability_domains.ads.availability_domains[0].name
      subnet_id           = var.worker_subnet_id
    }
    size = var.node_pool_size
  }
  
  # Shape configuration for Flex shapes
  dynamic "node_shape_config" {
    for_each = var.is_flex_shape ? [1] : []
    content {
      memory_in_gbs = var.memory_in_gbs
      ocpus         = var.ocpus
    }
  }

  initial_node_labels {
    key   = "name"
    value = var.node_pool_name
  }
  
  # Optional node taints
  dynamic "node_taints" {
    for_each = var.taints
    content {
      key    = node_taints.value.key
      value  = node_taints.value.value
      effect = node_taints.value.effect
    }
  }
  
  freeform_tags = merge(
    var.tags,
    { 
      "ResourceType" = "NodePool",
      "KubernetesVersion" = var.kubernetes_version,
      "NodeShape" = var.node_shape
    }
  )
}
