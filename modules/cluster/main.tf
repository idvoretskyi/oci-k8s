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
    
    // Configure admission controllers with modern Pod Security Standards
    admission_controller_options {
      is_pod_security_policy_enabled = false // Deprecated in K8s, removed in 1.25+
      
      // Enable OPA for advanced policy enforcement
      is_opa_gatekeeper_enabled = var.enable_pod_security_admission
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
      "KubernetesVersion" = var.kubernetes_version,
      "PodSecurityStandard" = var.enable_pod_security_admission ? "enabled" : "disabled"
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

// Deploy Pod Security Standards configurations
resource "null_resource" "deploy_pod_security_standards" {
  count = var.enable_pod_security_admission ? 1 : 0

  triggers = {
    cluster_id = oci_containerengine_cluster.oke_cluster.id
    kubernetes_version = var.kubernetes_version
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Deploying Pod Security Standards configuration..."
      
      # Ensure kubeconfig is available
      KUBECONFIG=${var.kubeconfig_path}
      
      # Wait for cluster to be fully ready
      echo "Waiting for cluster API to be accessible..."
      max_retries=30
      counter=0
      until kubectl --kubeconfig $KUBECONFIG get ns kube-system &>/dev/null || [ $counter -eq $max_retries ]; do
        sleep 10
        counter=$((counter + 1))
        echo "Waiting for cluster API... Attempt $counter of $max_retries"
      done
      
      if [ $counter -eq $max_retries ]; then
        echo "Failed to connect to cluster API, skipping Pod Security Standards deployment"
        exit 0
      fi
      
      # Deploy Gatekeeper
      echo "Deploying Gatekeeper for policy enforcement..."
      kubectl --kubeconfig $KUBECONFIG apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.14/deploy/gatekeeper.yaml
      
      # Wait for Gatekeeper to be ready
      echo "Waiting for Gatekeeper to be ready..."
      kubectl --kubeconfig $KUBECONFIG wait --for=condition=ready pod -l control-plane=controller-manager -n gatekeeper-system --timeout=300s
      
      # Deploy base Pod Security Standards constraints (prevent privileged containers, host namespace, etc.)
      echo "Deploying Pod Security Standards constraints..."
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
      
      # Create constraint to enforce
      echo "Creating enforcement constraint..."
      kubectl --kubeconfig $KUBECONFIG apply -f - <<EOF
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sPSPPrivilegedContainer
metadata:
  name: psp-privileged-container
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
    excludedNamespaces: ["kube-system", "gatekeeper-system"]
EOF
      
      echo "Pod Security Standards enforcement configured successfully"
    EOT
  }

  depends_on = [
    oci_containerengine_cluster.oke_cluster
  ]
}
