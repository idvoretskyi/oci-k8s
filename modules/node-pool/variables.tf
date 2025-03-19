/**
 * Variables for Node Pool Module
 */

variable "compartment_id" {
  description = "The OCID of the compartment where resources will be created"
  type        = string
}

variable "cluster_id" {
  description = "The OCID of the OKE cluster for this node pool"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the node pool"
  type        = string
}

variable "node_pool_name" {
  description = "Name of the node pool"
  type        = string
  default     = "node-pool"
}

variable "node_shape" {
  description = "Shape of the nodes in the pool"
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "worker_subnet_id" {
  description = "The OCID of the subnet for worker nodes"
  type        = string
}

variable "node_pool_size" {
  description = "Number of nodes in the node pool"
  type        = number
  default     = 3
}

variable "node_image_id" {
  description = "The OCID of the image to use for node pool instances. If not specified, the latest compatible image will be used."
  type        = string
  default     = null
}

variable "availability_domain" {
  description = "Availability domain for the nodes"
  type        = string
  default     = null
}

variable "os_name" {
  description = "Operating system for the nodes"
  type        = string
  default     = "Oracle Linux"
}

variable "os_version" {
  description = "Operating system version for the nodes"
  type        = string
  default     = "8"
}

variable "is_flex_shape" {
  description = "Whether the selected shape is a flex shape"
  type        = bool
  default     = true
}

variable "memory_in_gbs" {
  description = "Amount of memory in GBs for flex shapes"
  type        = number
  default     = 6
}

variable "ocpus" {
  description = "Number of OCPUs for flex shapes"
  type        = number
  default     = 1
}

variable "taints" {
  description = "List of Kubernetes taints to apply to nodes"
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
}

variable "tags" {
  description = "Freeform tags for resources"
  type        = map(string)
  default     = {}
}
