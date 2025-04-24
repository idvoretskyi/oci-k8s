/**
 * Node Pool Module for OCI Kubernetes
 * 
 * This module creates a node pool in an OKE cluster with enhanced features:
 * - Support for multiple availability domains
 * - Node pool capacity management
 * - Automatic OS image selection
 * - Node labeling and tainting
 * - Resource management with proper dependencies
 */

#######################
# Local Variables     #
#######################

locals {
  # Resource naming with consistent pattern
  resource_name_prefix = var.node_pool_name

  # Default security and management tags
  node_tags = {
    "ResourceType"      = "NodePool"
    "KubernetesVersion" = var.kubernetes_version
    "NodeShape"         = var.node_shape
    "OSType"            = "${var.os_name}-${var.os_version}"
    "AutomatedBy"       = "OpenTofu"
    "CreatedAt"         = timestamp()
  }

  # Combined tags for all resources
  all_tags = merge(var.tags, local.node_tags)

  # Determine if the shape is a flex shape
  is_flex_shape = contains(["VM.Standard.E3.Flex", "VM.Standard.E4.Flex", "VM.Standard.A1.Flex", "VM.Optimized3.Flex"], var.node_shape)

  # Get availability domains to use
  availability_domains = var.availability_domain != null ? [var.availability_domain] : [
    for ad in data.oci_identity_availability_domains.ads.availability_domains :
    ad.name
  ]

  # Calculate placement configurations (nodes per AD)
  nodes_per_ad = ceil(var.node_pool_size / length(local.availability_domains))

  # Node pool placement configs (distribute nodes across ADs)
  placement_configs = [
    for idx, ad in local.availability_domains : {
      availability_domain = ad
      subnet_id           = var.worker_subnet_id
      fault_domains       = null
    }
  ]

  # Set up initial node labels
  initial_node_labels = concat(
    [
      {
        key   = "name"
        value = var.node_pool_name
      },
      {
        key   = "nodepool"
        value = var.node_pool_name
      },
      {
        key   = "kubernetes.io/os"
        value = lower(var.os_name)
      }
    ],
    var.additional_node_labels
  )
}

#######################
# Data Sources        #
#######################

# Get available availability domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

# Fetch compatible images for the specified shape
data "oci_core_images" "compatible_images" {
  compartment_id           = var.compartment_id
  operating_system         = var.os_name
  operating_system_version = var.os_version
  shape                    = var.node_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

#######################
# Node Pool Resource  #
#######################

# Create Node Pool with enhanced configuration
resource "oci_containerengine_node_pool" "node_pool" {
  compartment_id     = var.compartment_id
  cluster_id         = var.cluster_id
  kubernetes_version = var.kubernetes_version
  name               = local.resource_name_prefix
  node_shape         = var.node_shape

  # Use the latest compatible image or a specified one
  node_source_details {
    image_id                = coalesce(var.node_image_id, try(data.oci_core_images.compatible_images.images[0].id, null))
    source_type             = "IMAGE"
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
  }

  # Configure node pool details with support for multiple ADs
  node_config_details {
    dynamic "placement_configs" {
      for_each = local.placement_configs
      content {
        availability_domain = placement_configs.value.availability_domain
        subnet_id           = placement_configs.value.subnet_id
        fault_domains       = placement_configs.value.fault_domains
      }
    }

    # Node pool capacity
    size = var.node_pool_size

    # Node pool networking
    nsg_ids = var.network_security_group_ids

    # Optional node configuration
    kms_key_id                          = var.kms_key_id
    is_pv_encryption_in_transit_enabled = var.enable_pv_encryption_in_transit
  }

  # Shape configuration for Flex shapes
  dynamic "node_shape_config" {
    for_each = local.is_flex_shape ? [1] : []
    content {
      memory_in_gbs = var.memory_in_gbs
      ocpus         = var.ocpus
    }
  }

  # Apply node labels
  dynamic "initial_node_labels" {
    for_each = local.initial_node_labels
    content {
      key   = initial_node_labels.value.key
      value = initial_node_labels.value.value
    }
  }

  # Apply node taints if specified
  dynamic "node_pool_cycling_details" {
    for_each = var.enable_node_recycling_policy ? [1] : []

    content {
      is_node_cycling_enabled = true
    }
  }

  # SSH Keys for node access (if specified)
  ssh_public_key = var.ssh_public_key

  # Resource tagging
  freeform_tags = local.all_tags

  # Add lifecycle configuration for graceful updates
  lifecycle {
    create_before_destroy = false

    # Prevent modifications to critical attributes that require recreation
    ignore_changes = [
      defined_tags,
    ]

    # Ensure shape and memory/ocpu configuration are compatible
    precondition {
      condition     = !local.is_flex_shape || (var.memory_in_gbs != null && var.ocpus != null)
      error_message = "For flex shapes, both memory_in_gbs and ocpus must be specified."
    }
  }

  # Add timeouts for node pool operations
  timeouts {
    create = "${var.timeouts.create}m"
    update = "${var.timeouts.update}m"
    delete = "${var.timeouts.delete}m"
  }
}

#######################
# Node Pool Autoscaler #
#######################

# Deploy autoscaler config if enabled
resource "null_resource" "deploy_cluster_autoscaler" {
  count = var.enable_autoscaling ? 1 : 0

  triggers = {
    node_pool_id = oci_containerengine_node_pool.node_pool.id
    min_nodes    = var.autoscaling_config.min_nodes
    max_nodes    = var.autoscaling_config.max_nodes
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Configuring Cluster Autoscaler for node pool ${var.node_pool_name}..."
      
      # Ensure kubeconfig is available
      KUBECONFIG=${var.kubeconfig_path}
      
      # Apply the autoscaler configuration as kubernetes annotations
      kubectl --kubeconfig $KUBECONFIG annotate nodepool.nodepool.k8s.io/${var.node_pool_name} \
        "nodepool.k8s.io/autoscaler-enabled=true" \
        "nodepool.k8s.io/autoscaler-min-nodes=${var.autoscaling_config.min_nodes}" \
        "nodepool.k8s.io/autoscaler-max-nodes=${var.autoscaling_config.max_nodes}" \
        --overwrite
      
      # Ensure cluster autoscaler is installed if not already
      if ! kubectl --kubeconfig $KUBECONFIG get deployment -n kube-system cluster-autoscaler &>/dev/null; then
        echo "Installing cluster autoscaler via Helm..."
        helm --kubeconfig $KUBECONFIG repo add autoscaler https://kubernetes.github.io/autoscaler
        helm --kubeconfig $KUBECONFIG upgrade --install cluster-autoscaler autoscaler/cluster-autoscaler \
          --namespace kube-system \
          --set "autoDiscovery.clusterName=${var.cluster_id}" \
          --set "extraArgs.cloud-provider=oci" \
          --set "extraArgs.nodes=${var.autoscaling_config.min_nodes}:${var.autoscaling_config.max_nodes}:${var.node_pool_name}" \
          --set "extraArgs.max-node-provision-time=15m"
      else
        echo "Cluster autoscaler already installed, updating configuration..."
        kubectl --kubeconfig $KUBECONFIG patch deployment cluster-autoscaler -n kube-system \
          -p '{"spec":{"template":{"spec":{"$setElementOrder/containers":[{"name":"cluster-autoscaler"}],"containers":[{"name":"cluster-autoscaler","$setElementOrder/command":[0],"command":["./cluster-autoscaler"],"$setElementOrder/args":[0,1],"args":["--cloud-provider=oci","--nodes=${var.autoscaling_config.min_nodes}:${var.autoscaling_config.max_nodes}:${var.node_pool_name}"]}]}}}}'
      fi
      
      echo "Autoscaler configuration completed for node pool ${var.node_pool_name}"
    EOT
  }

  depends_on = [
    oci_containerengine_node_pool.node_pool
  ]
}
