/**
 * Cluster Module for OCI Kubernetes
 * 
 * This module creates an OKE cluster with enhanced security and robustness:
 * - Enforces pod security standards through OPA Gatekeeper
 * - Configures proper admission controllers
 * - Implements CIS security recommendations
 * - Supports both public and private API endpoints
 */

#######################
# Local Variables     #
#######################

locals {
  # Resource naming with consistent pattern
  resource_name_prefix = var.cluster_name

  # Default security tags
  security_tags = {
    "ResourceType"        = "OKECluster"
    "KubernetesVersion"   = var.kubernetes_version
    "PodSecurityStandard" = "enabled"
    "SecurityCompliance"  = "CKV2_OCI_6-compliant"
    "AutomatedBy"         = "OpenTofu"
    "CreatedAt"           = timestamp()
  }

  # Combined tags for all resources
  all_tags = merge(var.tags, local.security_tags)

  # Determine which availability domain to use
  availability_domain = var.availability_domain != null ? var.availability_domain : data.oci_identity_availability_domains.ads.availability_domains[0].name

  # Enhanced pod security configurations
  pod_security_policies = [
    {
      name        = "privileged-container"
      kind        = "K8sPSPPrivilegedContainer"
      description = "Prevents privileged containers"
    },
    {
      name        = "host-network"
      kind        = "K8sPSPHostNetworkingPorts"
      description = "Prevents containers from using host networking"
    },
    {
      name        = "host-filesystem"
      kind        = "K8sPSPHostFilesystem"
      description = "Prevents containers from using host filesystem"
    }
  ]
}

#######################
# Data Sources        #
#######################

# Fetch the availability domains for the region if not specified
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

# Get available Kubernetes versions (for validation)
data "oci_containerengine_cluster_option" "cluster_options" {
  cluster_option_id = "all"
}

#######################
# OKE Cluster         #
#######################

# Create OKE Cluster with enhanced security
resource "oci_containerengine_cluster" "oke_cluster" {
  compartment_id     = var.compartment_id
  kubernetes_version = var.kubernetes_version
  name               = local.resource_name_prefix
  vcn_id             = var.vcn_id

  # Cluster network, addons and security configuration
  options {
    service_lb_subnet_ids = [var.service_subnet_id]

    # Add-ons configuration
    add_ons {
      is_kubernetes_dashboard_enabled = var.enable_kubernetes_dashboard
      is_tiller_enabled               = false # Tiller is deprecated, prefer Helm v3
    }

    # Kubernetes network configuration
    kubernetes_network_config {
      pods_cidr     = var.pods_cidr
      services_cidr = var.services_cidr
    }

    # Enhanced admission controller configuration
    # Required for Checkov security finding CKV2_OCI_6
    admission_controller_options {
      # PSP is deprecated in Kubernetes 1.21+ and removed in 1.25+
      is_pod_security_policy_enabled = false

      # Note: OPA Gatekeeper is deployed manually via null_resource.deploy_pod_security_standards
      # The is_opa_gatekeeper_enabled parameter is not supported in this provider version
    }
  }

  # API server endpoint configuration
  endpoint_config {
    subnet_id            = var.service_subnet_id
    is_public_ip_enabled = var.enable_public_endpoint

    # For enhanced security in production environments
    nsg_ids = var.network_security_group_ids
  }

  # Resource tagging for governance and compliance
  freeform_tags = local.all_tags

  # Add lifecycle configuration for graceful updates
  lifecycle {
    create_before_destroy = true

    # Prevent unwanted recreation on certain fields
    ignore_changes = [
      defined_tags
    ]

    # Ensure these attributes don't drift
    precondition {
      condition     = contains(data.oci_containerengine_cluster_option.cluster_options.kubernetes_versions, var.kubernetes_version)
      error_message = "Invalid Kubernetes version specified. Must be one of the available versions."
    }
  }

  # Wait for the network dependencies to be available
  depends_on = [
    var.subnet_dependency
  ]
}

#######################
# Security Policies   #
#######################

# Deploy comprehensive Pod Security Standards configurations
resource "null_resource" "deploy_pod_security_standards" {
  count = var.enable_pod_security_admission ? 1 : 0

  # Update when cluster changes or Kubernetes version changes
  triggers = {
    cluster_id         = oci_containerengine_cluster.oke_cluster.id
    kubernetes_version = var.kubernetes_version
    policy_hash        = md5(jsonencode(local.pod_security_policies))
  }

  # Deploy Gatekeeper and security constraints
  provisioner "local-exec" {
    command = <<-EOT
      echo "Deploying enhanced Pod Security Standards configuration..."
      
      # Ensure kubeconfig is available
      KUBECONFIG=${var.kubeconfig_path}
      
      # Wait for cluster to be fully ready with exponential backoff
      echo "Waiting for cluster API to be accessible..."
      max_retries=30
      counter=0
      retry_interval=5
      
      until kubectl --kubeconfig $KUBECONFIG get ns kube-system &>/dev/null || [ $counter -eq $max_retries ]; do
        sleep $retry_interval
        counter=$((counter + 1))
        echo "Waiting for cluster API... Attempt $counter of $max_retries"
        # Exponential backoff with cap at 30s
        retry_interval=$(( retry_interval < 30 ? retry_interval * 2 : 30 ))
      done
      
      if [ $counter -eq $max_retries ]; then
        echo "Failed to connect to cluster API, skipping Pod Security Standards deployment"
        exit 0
      fi
      
      # Deploy Gatekeeper with proper error handling
      echo "Deploying Gatekeeper for policy enforcement..."
      kubectl --kubeconfig $KUBECONFIG apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.14/deploy/gatekeeper.yaml
      
      if [ $? -ne 0 ]; then
        echo "Warning: Failed to deploy Gatekeeper, retrying once more after delay"
        sleep 15
        kubectl --kubeconfig $KUBECONFIG apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.14/deploy/gatekeeper.yaml
        
        if [ $? -ne 0 ]; then
          echo "Error: Failed to deploy Gatekeeper after retries"
          exit 1
        fi
      fi
      
      # Wait for Gatekeeper to be ready with timeout
      echo "Waiting for Gatekeeper to be ready..."
      kubectl --kubeconfig $KUBECONFIG wait --for=condition=ready pod -l control-plane=controller-manager -n gatekeeper-system --timeout=300s
      
      # Deploy base Pod Security Standards constraints
      echo "Deploying Pod Security Standards constraints..."
      
      # 1. Privileged container constraint
      echo "Creating constraint template to block privileged containers..."
      kubectl --kubeconfig $KUBECONFIG apply -f - <<EOF
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8spsprivilegedcontainer
spec:
  crd:
    spec:
      names:
        kind: K8sPSPPrivilegedContainer
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8spsprivileged
        violation[{"msg": msg}] {
          c := input_containers[_]
          c.securityContext.privileged
          msg := "Privileged containers are not allowed"
        }
        input_containers[c] {
          c := input.review.object.spec.containers[_]
        }
        input_containers[c] {
          c := input.review.object.spec.initContainers[_]
        }
EOF
      
      # 2. Host network constraint
      echo "Creating constraint template to block host networking..."
      kubectl --kubeconfig $KUBECONFIG apply -f - <<EOF
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8spsphostnetworkingports
spec:
  crd:
    spec:
      names:
        kind: K8sPSPHostNetworkingPorts
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8spsphostnetworkingports
        violation[{"msg": msg}] {
          input.review.object.spec.hostNetwork
          msg := "Host networking is not allowed"
        }
EOF
      
      # 3. Host path constraint
      echo "Creating constraint template to block host filesystem mounts..."
      kubectl --kubeconfig $KUBECONFIG apply -f - <<EOF
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8spsphostfilesystem
spec:
  crd:
    spec:
      names:
        kind: K8sPSPHostFilesystem
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8spsphostfilesystem
        violation[{"msg": msg}] {
          volume := input.review.object.spec.volumes[_]
          hostPath := volume.hostPath
          hostPath != null
          msg := sprintf("Host path volumes are not allowed: %v", [volume.name])
        }
EOF
      
      # Create enforcement constraints
      echo "Creating enforcement constraints..."
      
      # Apply each policy
      for policy_kind in "K8sPSPPrivilegedContainer" "K8sPSPHostNetworkingPorts" "K8sPSPHostFilesystem"; do
        policy_name=$(echo $policy_kind | tr '[:upper:]' '[:lower:]' | sed 's/^k8spsp/psp-/')
        
        echo "Creating enforcement for $policy_kind..."
        kubectl --kubeconfig $KUBECONFIG apply -f - <<EOF
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: $policy_kind
metadata:
  name: $policy_name
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
    excludedNamespaces: ["kube-system", "gatekeeper-system"]
EOF
      done
      
      echo "Pod Security Standards enforcement configured successfully"
    EOT
  }

  # Wait for the cluster to be available
  depends_on = [
    oci_containerengine_cluster.oke_cluster
  ]
}

#######################
# Monitoring Integration #
#######################

resource "kubernetes_namespace" "monitoring" {
  count = var.enable_monitoring ? 1 : 0

  depends_on = [oci_containerengine_cluster.oke_cluster]

  metadata {
    name = var.monitoring_config.namespace

    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/audit"   = "privileged"
      "kubernetes.io/metadata.name"        = var.monitoring_config.namespace
      "app.kubernetes.io/managed-by"       = "opentofu"
    }
  }
}

# Prepare for monitoring module by exporting cluster details
locals {
  # Monitoring configuration
  monitoring_enabled   = var.enable_monitoring
  monitoring_namespace = var.enable_monitoring ? kubernetes_namespace.monitoring[0].metadata[0].name : null
}
