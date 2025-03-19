/**
 * Main Terraform configuration for OCI Kubernetes Cluster
 */

provider "oci" {
  # Use defaults from ~/.oci/config or environment variables
}

# Define common tags
locals {
  common_tags = {
    "Project"     = "OCI Kubernetes"
    "Environment" = var.environment
    "ManagedBy"   = "Terraform"
    "Repo"        = "terraform-oci-k8s"
  }
}

# Network module creates VCN, subnets, and security lists
module "network" {
  source = "../modules/network"
  
  compartment_id      = var.compartment_id
  prefix              = var.resource_prefix
  vcn_cidr            = var.vcn_cidr
  service_subnet_cidr = var.service_subnet_cidr
  worker_subnet_cidr  = var.worker_subnet_cidr
  
  tags = local.common_tags
}

# Cluster module creates the OKE cluster
module "cluster" {
  source = "../modules/cluster"
  
  compartment_id     = var.compartment_id
  kubernetes_version = var.kubernetes_version
  cluster_name       = "${var.resource_prefix}-cluster"
  vcn_id             = module.network.vcn_id
  service_subnet_id  = module.network.service_subnet_id
  
  enable_public_endpoint = var.enable_public_endpoint
  
  tags = local.common_tags
}

# Node pool module creates worker nodes for the cluster
module "node_pool" {
  source = "../modules/node-pool"
  
  compartment_id     = var.compartment_id
  cluster_id         = module.cluster.cluster_id
  kubernetes_version = var.kubernetes_version
  node_pool_name     = "${var.resource_prefix}-node-pool"
  node_shape         = var.node_shape
  worker_subnet_id   = module.network.worker_subnet_id
  node_pool_size     = var.node_pool_size
  
  memory_in_gbs = var.node_memory_in_gbs
  ocpus         = var.node_ocpus
  
  tags = local.common_tags
}
