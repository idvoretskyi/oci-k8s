# ARM OKE Cluster Variables

variable "region" {
  description = "OCI region"
  type        = string
  default     = "uk-london-1"
}

variable "tenancy_ocid" {
  description = "Tenancy OCID (optional, read from ~/.oci/config if not provided)"
  type        = string
  default     = null
}

variable "compartment_ocid" {
  description = "Compartment OCID (optional, uses tenancy if not provided)"
  type        = string
  default     = null
}

variable "user_ocid" {
  description = "User OCID (optional, read from ~/.oci/config if not provided)"
  type        = string
  default     = null
}

variable "fingerprint" {
  description = "API key fingerprint (optional)"
  type        = string
  default     = null
}

variable "private_key_path" {
  description = "Path to private key for API access"
  type        = string
  default     = null
}

variable "cluster_name" {
  description = "Name of the ARM OKE cluster"
  type        = string
  default     = "arm-oke-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "v1.33.0"
}

variable "node_count" {
  description = "Number of ARM worker nodes"
  type        = number
  default     = 2
}

variable "node_memory_gb" {
  description = "Memory per ARM node in GB"
  type        = number
  default     = 8
}

variable "node_ocpus" {
  description = "OCPUs per ARM node"
  type        = number
  default     = 2
}