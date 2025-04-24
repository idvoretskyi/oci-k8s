/**
 * Variables for Network Module
 * Defines all configurable parameters for the OCI Kubernetes network infrastructure
 */

#######################
# Core Parameters     #
#######################

variable "compartment_id" {
  description = "OCID of the compartment where network resources will be created"
  type        = string
}

variable "prefix" {
  description = "Prefix for resource names (will be used in display names and DNS labels)"
  type        = string
  default     = "k8s"

  validation {
    condition     = can(regex("^[a-zA-Z0-9]+$", var.prefix)) && length(var.prefix) <= 8
    error_message = "Prefix must be alphanumeric and 8 characters or less (used in DNS labels)."
  }
}

variable "environment" {
  description = "Environment name (e.g. dev, staging, prod) for resource tagging"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource tagging and identification"
  type        = string
  default     = "k8s"
}

variable "authorized_ip_ranges" {
  description = "List of CIDR blocks authorized for API access"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Default to allow from anywhere, should be restricted in production
}

#######################
# Network CIDRs       #
#######################

variable "vcn_cidr" {
  description = "CIDR block for the Virtual Cloud Network"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vcn_cidr))
    error_message = "VCN CIDR must be a valid CIDR block."
  }
}

variable "service_subnet_cidr" {
  description = "CIDR block for the Kubernetes API service subnet"
  type        = string
  default     = "10.0.1.0/24"

  validation {
    condition     = can(cidrnetmask(var.service_subnet_cidr))
    error_message = "Service subnet CIDR must be a valid CIDR block."
  }
}

variable "worker_subnet_cidr" {
  description = "CIDR block for the worker node subnet"
  type        = string
  default     = "10.0.2.0/24"

  validation {
    condition     = can(cidrnetmask(var.worker_subnet_cidr))
    error_message = "Worker subnet CIDR must be a valid CIDR block."
  }
}

#######################
# Security Parameters #
#######################

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed for SSH access to worker nodes. For production, specify a restricted IP range."
  type        = string
  default     = "127.0.0.1/32" # Default to localhost only - users must explicitly set allowed IPs

  validation {
    condition     = can(cidrnetmask(var.allowed_ssh_cidr))
    error_message = "SSH CIDR must be a valid CIDR block."
  }
}

variable "allowed_api_cidr" {
  description = "CIDR block allowed for Kubernetes API access. Should be restricted in production."
  type        = string
  default     = "0.0.0.0/0" # Default to anywhere - should be restricted in production

  validation {
    condition     = can(cidrnetmask(var.allowed_api_cidr))
    error_message = "API CIDR must be a valid CIDR block."
  }
}

variable "enable_public_ips" {
  description = "Whether to enable public IPs on subnet VNICs (set to false for private worker nodes)"
  type        = bool
  default     = true
}

#######################
# Advanced Options    #
#######################

variable "create_nat_gateway" {
  description = "Whether to create a NAT Gateway for private subnets (automatically set if enable_public_ips is false)"
  type        = bool
  default     = null # Will be derived from enable_public_ips if not specified
}

variable "create_service_gateway" {
  description = "Whether to create a Service Gateway for OCI services access"
  type        = bool
  default     = true
}

variable "create_separate_worker_seclist" {
  description = "Whether to create a separate security list for worker nodes (recommended for production)"
  type        = bool
  default     = true
}

#######################
# Tagging             #
#######################

variable "tags" {
  description = "Freeform tags to be applied to all resources created by this module"
  type        = map(string)
  default     = {}
}
