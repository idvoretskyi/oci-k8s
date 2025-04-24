/**
 * Variables for Node Pool Module
 * Defines all configurable parameters for OCI Kubernetes node pools
 */

#######################
# Core Parameters     #
#######################

variable "compartment_id" {
  description = "The OCID of the compartment where the node pool will be created"
  type        = string
}

variable "cluster_id" {
  description = "The OCID of the OKE cluster for this node pool"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the node pool (should match cluster version)"
  type        = string

  validation {
    condition     = length(regexall("^v[0-9]+\\.[0-9]+\\.[0-9]+$", var.kubernetes_version)) > 0
    error_message = "Kubernetes version must match pattern 'vX.Y.Z' (e.g., v1.32.1)."
  }
}

variable "node_pool_name" {
  description = "Name of the node pool (will be used in display name and node labels)"
  type        = string

  validation {
    condition     = length(var.node_pool_name) >= 1 && length(var.node_pool_name) <= 63
    error_message = "Node pool name must be between 1 and 63 characters."
  }
}

#######################
# Compute Configuration #
#######################

variable "node_shape" {
  description = "Shape of the nodes in the pool (e.g. VM.Standard.A1.Flex, VM.Standard.E4.Flex)"
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "node_pool_size" {
  description = "Number of nodes in the node pool"
  type        = number
  default     = 3

  validation {
    condition     = var.node_pool_size > 0
    error_message = "Node pool size must be greater than zero."
  }
}

variable "memory_in_gbs" {
  description = "Amount of memory in GBs for flex shape nodes"
  type        = number
  default     = 6

  validation {
    condition     = var.memory_in_gbs >= 1
    error_message = "Memory must be at least 1 GB."
  }
}

variable "ocpus" {
  description = "Number of OCPUs for flex shape nodes"
  type        = number
  default     = 1

  validation {
    condition     = var.ocpus >= 1
    error_message = "OCPUs must be at least 1."
  }
}

variable "boot_volume_size_in_gbs" {
  description = "Size of the boot volume in GB"
  type        = number
  default     = 50

  validation {
    condition     = var.boot_volume_size_in_gbs >= 50
    error_message = "Boot volume size must be at least 50 GB."
  }
}

#######################
# OS Configuration    #
#######################

variable "node_image_id" {
  description = "The OCID of the image to use for node pool instances (if null, latest compatible image is used)"
  type        = string
  default     = null
}

variable "os_name" {
  description = "Operating system for the nodes (e.g., 'Oracle Linux')"
  type        = string
  default     = "Oracle Linux"
}

variable "os_version" {
  description = "Operating system version for the nodes (e.g., '8')"
  type        = string
  default     = "8"
}

variable "ssh_public_key" {
  description = "SSH public key for node access (optional)"
  type        = string
  default     = ""
}

#######################
# Network Configuration #
#######################

variable "worker_subnet_id" {
  description = "The OCID of the subnet for worker nodes"
  type        = string
}

variable "availability_domain" {
  description = "Specific availability domain for the nodes (if null, nodes will be distributed across ADs)"
  type        = string
  default     = null
}

variable "network_security_group_ids" {
  description = "List of Network Security Group OCIDs for worker nodes"
  type        = list(string)
  default     = []
}

#######################
# Kubernetes Configuration #
#######################

variable "additional_node_labels" {
  description = "Additional Kubernetes node labels to apply"
  type = list(object({
    key   = string
    value = string
  }))
  default = []
}

variable "node_taints" {
  description = "Kubernetes taints to apply to nodes"
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
}

#######################
# Security Configuration #
#######################

variable "kms_key_id" {
  description = "OCID of the KMS key for node volume encryption (if using OCI Vault)"
  type        = string
  default     = null
}

variable "enable_pv_encryption_in_transit" {
  description = "Whether to enable in-transit encryption for Persistent Volumes"
  type        = bool
  default     = true
}

#######################
# Scaling Configuration #
#######################

variable "enable_autoscaling" {
  description = "Whether to enable cluster autoscaling for this node pool"
  type        = bool
  default     = false
}

variable "autoscaling_config" {
  description = "Configuration for node pool autoscaling (if enabled)"
  type = object({
    min_nodes = number
    max_nodes = number
  })
  default = {
    min_nodes = 1
    max_nodes = 10
  }

  validation {
    condition     = var.autoscaling_config.min_nodes > 0 && var.autoscaling_config.max_nodes >= var.autoscaling_config.min_nodes
    error_message = "min_nodes must be greater than 0 and max_nodes must be greater than or equal to min_nodes."
  }
}

variable "enable_node_recycling_policy" {
  description = "Whether to enable node recycling policy for maintenance"
  type        = bool
  default     = false
}

variable "node_replacement_strategy" {
  description = "Strategy for replacing nodes during maintenance"
  type        = string
  default     = "DRAIN_AND_REPLACE"

  validation {
    condition     = contains(["DRAIN_AND_REPLACE", "REPLACE_THEN_DRAIN"], var.node_replacement_strategy)
    error_message = "Node replacement strategy must be either DRAIN_AND_REPLACE or REPLACE_THEN_DRAIN."
  }
}

#######################
# Runtime Settings    #
#######################

variable "kubeconfig_path" {
  description = "Path to kubeconfig file for accessing the cluster"
  type        = string
  default     = "~/.kube/config"
}

variable "timeouts" {
  description = "Timeouts for node pool operations in minutes"
  type = object({
    create = number
    update = number
    delete = number
  })
  default = {
    create = 30
    update = 30
    delete = 30
  }
}

#######################
# Tagging             #
#######################

variable "tags" {
  description = "Freeform tags to be applied to all resources created by this module"
  type        = map(string)
  default     = {}
}
