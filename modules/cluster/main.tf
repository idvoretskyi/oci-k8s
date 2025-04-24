/**
 * Cluster Module for OCI Kubernetes
 * 
 * This module creates an OKE cluster with the specified configuration
 */

// Fetch the first availability domain for the region if not specified
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

// Create OKE Cluster
resource "oci_containerengine_cluster" "oke_cluster" {
  compartment_id     = var.compartment_id
  kubernetes_version = var.kubernetes_version
  name               = var.cluster_name
  vcn_id             = var.vcn_id
  
  options {
    service_lb_subnet_ids = [var.service_subnet_id]
    
    add_ons {
      is_kubernetes_dashboard_enabled = var.enable_kubernetes_dashboard
      is_tiller_enabled               = false  // Tiller is deprecated
    }
    
    kubernetes_network_config {
      pods_cidr     = var.pods_cidr
      services_cidr = var.services_cidr
    }
    
    admission_controller_options {
      is_pod_security_policy_enabled = var.enable_pod_security_policy
    }
  }

  endpoint_config {
    subnet_id            = var.service_subnet_id
    is_public_ip_enabled = var.enable_public_endpoint
  }
  
  freeform_tags = merge(
    var.tags,
    { 
      "ResourceType" = "OKECluster",
      "KubernetesVersion" = var.kubernetes_version
    }
  )

  # Add lifecycle configuration to handle dependencies
  lifecycle {
    create_before_destroy = true
  }
  
  # Wait for the null resource to handle subnet dependencies
  depends_on = [
    var.subnet_dependency
  ]
}
