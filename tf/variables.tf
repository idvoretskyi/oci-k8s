/**
 * Variables for the OCI Kubernetes project with OpenTofu
 * Organized by functional categories with validation rules
 */

#######################
# OCI Authentication  #
#######################

variable "region" {
  description = "OCI region identifier (e.g., uk-london-1, us-ashburn-1)"
  type        = string
}

variable "compartment_id" {
  description = "OCID of the compartment where resources will be created"
  type        = string
}

variable "tenancy_ocid" {
  description = "OCID of the tenancy (root compartment)"
  type        = string
  default     = null
}

variable "oci_profile" {
  description = "OCI CLI profile name for authentication"
  type        = string
  default     = "DEFAULT"
}

variable "user_ocid" {
  description = "OCID of the user (optional if using config file authentication)"
  type        = string
  default     = null
}

variable "fingerprint" {
  description = "API key fingerprint (optional if using config file authentication)"
  type        = string
  default     = null
}

variable "private_key_path" {
  description = "Path to the API private key file"
  type        = string
  default     = "~/.oci/oci_api_key.pem"
}

variable "private_key_password" {
  description = "Password for encrypted private key"
  type        = string
  default     = null
  sensitive   = true
}

#######################
# Resource Naming     #
#######################

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod", "test"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, or test."
  }
}

variable "username" {
  description = "Username prefix for resources (defaults to current system user)"
  type        = string
  default     = null
}

variable "resource_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "k8s"

  validation {
    condition     = length(var.resource_prefix) >= 2 && length(var.resource_prefix) <= 10
    error_message = "Resource prefix must be between 2-10 characters."
  }
}

#######################
# Network Settings    #
#######################

variable "vcn_cidr" {
  description = "CIDR block for the Virtual Cloud Network"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vcn_cidr))
    error_message = "Must be a valid CIDR block."
  }
}

variable "service_subnet_cidr" {
  description = "CIDR block for the Kubernetes API service subnet"
  type        = string
  default     = "10.0.1.0/24"

  validation {
    condition     = can(cidrnetmask(var.service_subnet_cidr))
    error_message = "Must be a valid CIDR block."
  }
}

variable "worker_subnet_cidr" {
  description = "CIDR block for the worker node subnet"
  type        = string
  default     = "10.0.2.0/24"

  validation {
    condition     = can(cidrnetmask(var.worker_subnet_cidr))
    error_message = "Must be a valid CIDR block."
  }
}

#######################
# Kubernetes Settings #
#######################

variable "kubernetes_version" {
  description = "Kubernetes version for the OKE cluster (e.g., v1.32.1)"
  type        = string
  default     = "v1.32.1"

  validation {
    condition     = length(regexall("^v[0-9]+\\.[0-9]+\\.[0-9]+$", var.kubernetes_version)) > 0
    error_message = "Kubernetes version must match pattern 'vX.Y.Z' (e.g., v1.32.1)."
  }
}

variable "enable_kubernetes_dashboard" {
  description = "Whether to enable the Kubernetes dashboard add-on"
  type        = bool
  default     = true
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
    error_message = "Must be a valid CIDR block."
  }
}

variable "services_cidr" {
  description = "CIDR block for Kubernetes services networking"
  type        = string
  default     = "10.96.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.services_cidr))
    error_message = "Must be a valid CIDR block."
  }
}

variable "kubeconfig_path" {
  description = "Path where kubeconfig file will be saved"
  type        = string
  default     = "~/.kube/config"
}

variable "k8s_connection_max_retries" {
  description = "Maximum number of connection attempts to Kubernetes API"
  type        = number
  default     = 60

  validation {
    condition     = var.k8s_connection_max_retries > 0
    error_message = "Must be a positive number."
  }
}

variable "k8s_connection_retry_interval" {
  description = "Seconds to wait between Kubernetes API connection attempts"
  type        = number
  default     = 10

  validation {
    condition     = var.k8s_connection_retry_interval >= 5
    error_message = "Retry interval must be at least 5 seconds."
  }
}

#######################
# Node Pool Settings  #
#######################

variable "node_pool_size" {
  description = "Number of worker nodes in the node pool"
  type        = number
  default     = 3

  validation {
    condition     = var.node_pool_size >= 1
    error_message = "At least one worker node is required."
  }
}

variable "node_shape" {
  description = "Shape (instance type) for worker nodes"
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "node_image_id" {
  description = "OCID of the OS image for worker nodes (auto-selected if null)"
  type        = string
  default     = null
}

variable "availability_domain" {
  description = "Availability domain for worker nodes (auto-selected if null)"
  type        = string
  default     = null
}

variable "node_memory_in_gbs" {
  description = "Memory allocation in GB for Flex shape nodes"
  type        = number
  default     = 6

  validation {
    condition     = var.node_memory_in_gbs >= 6
    error_message = "Memory must be at least 6 GB for worker nodes."
  }
}

variable "node_ocpus" {
  description = "Number of OCPUs for Flex shape nodes"
  type        = number
  default     = 1

  validation {
    condition     = var.node_ocpus >= 1
    error_message = "At least 1 OCPU is required for worker nodes."
  }
}

#######################
# Security Settings   #
#######################

variable "enable_pod_security_admission" {
  description = "Whether to enable Pod Security Standards enforcement"
  type        = bool
  default     = true
}

#######################
# Monitoring Settings #
#######################

variable "enable_monitoring" {
  description = "Whether to deploy the monitoring stack"
  type        = bool
  default     = true
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana dashboard"
  type        = string
  default     = "admin" # Should be overridden in production
  sensitive   = true

  validation {
    condition     = length(var.grafana_admin_password) >= 5
    error_message = "Grafana admin password must be at least 5 characters."
  }
}

variable "prometheus_storage_size" {
  description = "Storage size for Prometheus time-series database"
  type        = string
  default     = "10Gi"

  validation {
    condition     = can(regex("^[0-9]+[GMTgmt][i]?$", var.prometheus_storage_size))
    error_message = "Storage size must be in the format '10Gi', '20Gi', etc."
  }
}

variable "grafana_storage_size" {
  description = "Storage size for Grafana dashboards and data"
  type        = string
  default     = "5Gi"

  validation {
    condition     = can(regex("^[0-9]+[GMTgmt][i]?$", var.grafana_storage_size))
    error_message = "Storage size must be in the format '5Gi', '10Gi', etc."
  }
}

variable "enable_loki" {
  description = "Whether to enable Loki log aggregation"
  type        = bool
  default     = true
}
