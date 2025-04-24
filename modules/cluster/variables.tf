/**
 * Variables for Cluster Module
 * Defines all configurable parameters for the OCI Kubernetes cluster
 */

#######################
# Core Parameters     #
#######################

variable "compartment_id" {
  description = "The OCID of the compartment where the cluster will be created"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the OKE cluster (e.g., v1.32.1)"
  type        = string

  validation {
    condition     = length(regexall("^v[0-9]+\\.[0-9]+\\.[0-9]+$", var.kubernetes_version)) > 0
    error_message = "Kubernetes version must match pattern 'vX.Y.Z' (e.g., v1.32.1)."
  }
}

variable "cluster_name" {
  description = "Name of the OKE cluster (will be used in display name)"
  type        = string

  validation {
    condition     = length(var.cluster_name) >= 3 && length(var.cluster_name) <= 63
    error_message = "Cluster name must be between 3 and 63 characters."
  }
}

variable "availability_domain" {
  description = "Availability domain for the cluster resources (auto-selected if null)"
  type        = string
  default     = null
}

#######################
# Network Parameters  #
#######################

variable "vcn_id" {
  description = "The OCID of the VCN where the cluster will be created"
  type        = string
}

variable "service_subnet_id" {
  description = "The OCID of the subnet for Kubernetes API and Service LBs"
  type        = string
}

variable "network_security_group_ids" {
  description = "List of Network Security Group OCIDs for the cluster endpoint"
  type        = list(string)
  default     = []
}

variable "enable_public_endpoint" {
  description = "Whether to create a public endpoint for the Kubernetes API"
  type        = bool
  default     = true
}

variable "pods_cidr" {
  description = "CIDR block for Kubernetes pods networking"
  type        = string
  default     = "10.244.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.pods_cidr))
    error_message = "Pods CIDR must be a valid CIDR block."
  }
}

variable "services_cidr" {
  description = "CIDR block for Kubernetes services networking"
  type        = string
  default     = "10.96.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.services_cidr))
    error_message = "Services CIDR must be a valid CIDR block."
  }
}

variable "subnet_dependency" {
  description = "Dependency reference for subnet resources to ensure proper ordering"
  type        = any
  default     = null
}

#######################
# Add-ons & Features  #
#######################

variable "enable_kubernetes_dashboard" {
  description = "Whether to enable the Kubernetes dashboard add-on"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Whether to enable integrated monitoring deployment with the cluster"
  type        = bool
  default     = false
}

variable "monitoring_config" {
  description = "Configuration settings for the monitoring stack when enabled"
  type = object({
    namespace               = optional(string, "monitoring")
    prometheus_storage_size = optional(string, "50Gi")
    grafana_storage_size    = optional(string, "10Gi")
    enable_alertmanager     = optional(bool, true)
    enable_loki             = optional(bool, false)
    enable_tempo            = optional(bool, false)
    retention_period        = optional(string, "15d")
    scrape_interval         = optional(string, "30s")
    storage_class_name      = optional(string, null)
  })
  default = {}
}

#######################
# Security Settings   #
#######################

variable "enable_pod_security_admission" {
  description = "Whether to enable Pod Security Standards enforcement via OPA Gatekeeper"
  type        = bool
  default     = true
}

variable "additional_security_policies" {
  description = "List of additional OPA/Gatekeeper security policies to apply"
  type = list(object({
    name               = string
    kind               = string
    exclude_namespaces = list(string)
  }))
  default = []
}

variable "kms_key_id" {
  description = "OCID of the KMS key for cluster encryption (if using OCI Vault)"
  type        = string
  default     = null
}

#######################
# Runtime Settings    #
#######################

variable "kubeconfig_path" {
  description = "Path to kubeconfig file for accessing the cluster"
  type        = string
  default     = "~/.kube/config"
}

variable "setup_timeout_minutes" {
  description = "Timeout for the cluster setup operations (in minutes)"
  type        = number
  default     = 30

  validation {
    condition     = var.setup_timeout_minutes >= 10
    error_message = "Timeout must be at least 10 minutes for cluster operations."
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
