/**
 * Main OpenTofu configuration for OCI Kubernetes Cluster
 * Organized with infrastructure layers and proper dependency management
 */

# Define common variables and configurations
locals {
  # Common tags for all resources
  common_tags = {
    "Project"     = "OCI-Kubernetes"
    "Environment" = var.environment
    "ManagedBy"   = "OpenTofu"
    "Repo"        = "oci-k8s"
    "CreatedAt"   = timestamp()
  }

  # Resource naming with consistent patterns
  current_user = coalesce(
    var.username,
    try(trimspace(data.external.current_user.result.user), "user")
  )
  cluster_name   = "${local.current_user}-${var.resource_prefix}-cluster"
  node_pool_name = "${var.resource_prefix}-node-pool"

  # Status management
  status_dir          = "${path.module}/.status"
  k8s_api_status_file = "${local.status_dir}/k8s_api_status"
  k8s_api_reachable   = fileexists(local.k8s_api_status_file) ? file(local.k8s_api_status_file) == "reachable" : false

  # Command construction
  kubeconfig_cmd = "oci ce cluster create-kubeconfig --cluster-id ${module.cluster.cluster_id} --file ${var.kubeconfig_path} --region ${var.region} --token-version 2.0.0"

  # Component activation flags
  monitoring_enabled   = var.enable_monitoring && local.k8s_api_reachable
  pod_security_enabled = var.enable_pod_security_admission && local.k8s_api_reachable
}

# Get current username using an external data source
data "external" "current_user" {
  program = ["sh", "-c", "echo \"{\\\"user\\\":\\\"$(whoami)\\\"}\""]
}

###################
# Infrastructure Layer
###################

# Network infrastructure (VCN, Subnets, Security Lists)
module "network" {
  source = "../modules/network"

  compartment_id      = var.compartment_id
  prefix              = var.resource_prefix
  vcn_cidr            = var.vcn_cidr
  service_subnet_cidr = var.service_subnet_cidr
  worker_subnet_cidr  = var.worker_subnet_cidr
  enable_public_ips   = var.enable_public_endpoint

  tags = local.common_tags
}

# OKE Cluster 
module "cluster" {
  source = "../modules/cluster"

  compartment_id                = var.compartment_id
  kubernetes_version            = var.kubernetes_version
  cluster_name                  = local.cluster_name
  vcn_id                        = module.network.vcn_id
  service_subnet_id             = module.network.service_subnet_id
  enable_public_endpoint        = var.enable_public_endpoint
  subnet_dependency             = module.network.subnet_dependency
  enable_pod_security_admission = var.enable_pod_security_admission
  kubeconfig_path               = var.kubeconfig_path

  tags = local.common_tags
}

# Worker Node Pool
module "node_pool" {
  source = "../modules/node-pool"

  compartment_id     = var.compartment_id
  cluster_id         = module.cluster.cluster_id
  kubernetes_version = var.kubernetes_version
  node_pool_name     = local.node_pool_name
  node_shape         = var.node_shape
  worker_subnet_id   = module.network.worker_subnet_id
  node_pool_size     = var.node_pool_size
  memory_in_gbs      = var.node_memory_in_gbs
  ocpus              = var.node_ocpus

  tags = local.common_tags
}

###################
# Kubernetes Setup
###################

# Generate and validate kubeconfig
resource "null_resource" "kubeconfig_setup" {
  triggers = {
    cluster_id      = module.cluster.cluster_id
    kubeconfig_path = var.kubeconfig_path
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Create required directories
      mkdir -p $(dirname ${var.kubeconfig_path})
      mkdir -p ${local.status_dir}
      
      # Generate kubeconfig
      echo "Setting up kubeconfig..."
      ${local.kubeconfig_cmd}
      chmod 600 ${var.kubeconfig_path}
      
      # Wait for Kubernetes API to become available
      echo "Waiting for Kubernetes API to become available..."
      for i in {1..${var.k8s_connection_max_retries}}; do
        if kubectl --kubeconfig ${var.kubeconfig_path} get nodes &>/dev/null; then
          echo "Successfully connected to Kubernetes API!"
          echo "reachable" > ${local.k8s_api_status_file}
          exit 0
        fi
        
        echo "Attempt $i/${var.k8s_connection_max_retries}: Waiting ${var.k8s_connection_retry_interval}s..."
        sleep ${var.k8s_connection_retry_interval}
      done
      
      echo "ERROR: Failed to connect to Kubernetes API after ${var.k8s_connection_max_retries} attempts"
      echo "unreachable" > ${local.k8s_api_status_file}
    EOT
  }

  depends_on = [
    module.cluster,
    module.node_pool
  ]
}

###################
# Security Layer
###################

# Configure Pod Security Standards
resource "null_resource" "pod_security_standards" {
  count = local.pod_security_enabled ? 1 : 0

  triggers = {
    cluster_id = module.cluster.cluster_id
    api_status = local.k8s_api_reachable
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Configuring Pod Security Standards for the cluster..."
      
      # Create Pod Security Standards configuration
      cat <<EOF | kubectl --kubeconfig ${var.kubeconfig_path} apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: pod-security-admission-config
  namespace: kube-system
  labels:
    app.kubernetes.io/name: pod-security-admission
    app.kubernetes.io/part-of: kubernetes
    app.kubernetes.io/managed-by: opentofu
data:
  admission-control-config.yaml: |
    apiVersion: apiserver.config.k8s.io/v1
    kind: AdmissionConfiguration
    plugins:
    - name: PodSecurity
      configuration:
        apiVersion: pod-security.admission.config.k8s.io/v1
        kind: PodSecurityConfiguration
        defaults:
          enforce: "baseline"
          enforce-version: "latest"
          audit: "restricted"
          audit-version: "latest"
          warn: "restricted"
          warn-version: "latest"
        exemptions:
          usernames: []
          runtimeClasses: []
          namespaces: [kube-system, kube-public, kube-node-lease]
EOF
      
      # Apply Pod Security Standards to namespaces
      for ns in default monitoring; do
        kubectl --kubeconfig ${var.kubeconfig_path} get namespace $ns >/dev/null 2>&1 || \
          kubectl --kubeconfig ${var.kubeconfig_path} create namespace $ns
        
        kubectl --kubeconfig ${var.kubeconfig_path} label --overwrite namespace $ns \
          pod-security.kubernetes.io/enforce=baseline \
          pod-security.kubernetes.io/audit=restricted \
          pod-security.kubernetes.io/warn=restricted || \
          echo "Warning: Failed to apply Pod Security labels to namespace $ns"
      done
      
      echo "Pod Security Standards configuration completed"
    EOT
  }

  depends_on = [
    null_resource.kubeconfig_setup
  ]
}

###################
# Monitoring Layer
###################

# Deploy monitoring stack (Prometheus, Grafana, Alertmanager)
module "monitoring" {
  source = "../modules/monitoring"
  count  = local.monitoring_enabled ? 1 : 0

  namespace               = "monitoring"
  storage_class_name      = "oci-bv"
  prometheus_storage_size = var.prometheus_storage_size
  grafana_storage_size    = var.grafana_storage_size
  grafana_admin_password  = var.grafana_admin_password
  enable_loki             = var.enable_loki
  kubeconfig_path         = var.kubeconfig_path

  labels = merge(
    local.common_tags,
    { "Component" = "Monitoring" }
  )

  depends_on = [
    null_resource.kubeconfig_setup,
    null_resource.pod_security_standards
  ]
}
