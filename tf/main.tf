/**
 * Main OpenTofu configuration for OCI Kubernetes Cluster
 */

# Define common tags and variables
locals {
  common_tags = {
    "Project"     = "OCI-Kubernetes"
    "Environment" = var.environment
    "ManagedBy"   = "OpenTofu"  # Changed from Terraform to OpenTofu
    "Repo"        = "opentofu-oci-k8s"  # Updated repository name
  }
  
  # More reliable way to get username using external data source
  # This fixes the issue where usernames were being incorrectly detected
  current_user = var.username != null ? var.username : trimspace(
    lookup(
      {
        for pair in regexall("([^:]+):([^:]+):([^:]+):([^:]+):([^:]*):(.*)", file("/etc/passwd")) :
        pair[0] => pair[4]
      },
      data.external.current_user.result.user,
      data.external.current_user.result.user
    )
  )
}

# Get current username using an external data source
data "external" "current_user" {
  program = ["sh", "-c", "echo \"{\\\"user\\\":\\\"$(whoami)\\\"}\""]
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
  cluster_name       = "${local.current_user}-${var.resource_prefix}-cluster"  # Using correctly determined username
  vcn_id             = module.network.vcn_id
  service_subnet_id  = module.network.service_subnet_id
  
  enable_public_endpoint = var.enable_public_endpoint
  
  # Add subnet dependency reference
  subnet_dependency = module.network.subnet_dependency
  
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

# Ensure kubeconfig is properly set up and verify connectivity before proceeding
resource "null_resource" "kubeconfig_setup" {
  provisioner "local-exec" {
    command = <<-EOT
      echo "Setting up kubeconfig..."
      oci ce cluster create-kubeconfig --cluster-id ${module.cluster.cluster_id} --file ${var.kubeconfig_path} --region ${var.region} --token-version 2.0.0
      chmod 600 ${var.kubeconfig_path}
      echo "Kubeconfig created at ${var.kubeconfig_path}"
      
      # Wait for Kubernetes API to become available
      echo "Waiting for Kubernetes API to become available..."
      max_retries=60
      counter=0
      success=false
      
      while [ $counter -lt $max_retries ]; do
        if kubectl --kubeconfig ${var.kubeconfig_path} get nodes &>/dev/null; then
          echo "Successfully connected to Kubernetes API!"
          success=true
          break
        fi
        
        echo "Attempt $counter/$max_retries: Kubernetes API not yet available, waiting 10 seconds..."
        sleep 10
        counter=$((counter + 1))
      done
      
      # Create a k8s_api_status file for tracking API reachability
      mkdir -p ${path.module}/.status
      if [ "$success" != "true" ]; then
        echo "ERROR: Failed to connect to Kubernetes API after $max_retries attempts"
        echo "Skipping monitoring deployment"
        echo "unreachable" > ${path.module}/.status/k8s_api_status
      else
        echo "Kubernetes API is available, proceeding with deployment"
        echo "reachable" > ${path.module}/.status/k8s_api_status
      fi
    EOT
  }

  depends_on = [
    module.cluster,
    module.node_pool
  ]
}

# Use file existence function for simplicity - no data source needed
locals {
  k8s_api_status_file = "${path.module}/.status/k8s_api_status"
  # Fix the multi-line ternary expression with proper formatting
  k8s_api_reachable = fileexists(local.k8s_api_status_file) ? file(local.k8s_api_status_file) == "reachable" : false
}

# Monitoring module - deploys Prometheus, Grafana, and Alertmanager
module "monitoring" {
  source = "../modules/monitoring"
  count  = var.enable_monitoring && local.k8s_api_reachable ? 1 : 0
  
  namespace = "monitoring"
  
  # Use OCI Block Volume storage class
  storage_class_name = "oci-bv"
  
  # Customize storage sizes if needed
  prometheus_storage_size = var.prometheus_storage_size
  grafana_storage_size    = var.grafana_storage_size
  
  # Set secure Grafana admin password
  grafana_admin_password = var.grafana_admin_password
  
  # Enable Loki for log collection
  enable_loki = var.enable_loki
  
  # Path to kubeconfig after cluster creation
  kubeconfig_path = var.kubeconfig_path
  
  # Label all resources
  labels = merge(
    local.common_tags,
    {
      "Component" = "Monitoring"
    }
  )
  
  depends_on = [
    module.node_pool,
    null_resource.kubeconfig_setup
  ]
}
