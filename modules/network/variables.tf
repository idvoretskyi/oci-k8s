/**
 * Variables for Network Module
 */

variable "compartment_id" {
  description = "The OCID of the compartment where resources will be created"
  type        = string
}

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "k8s"
}

variable "vcn_cidr" {
  description = "CIDR block for the VCN"
  type        = string
  default     = "10.0.0.0/16"
}

variable "service_subnet_cidr" {
  description = "CIDR block for the Kubernetes API service subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "worker_subnet_cidr" {
  description = "CIDR block for the worker node subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed for SSH access. For production, specify a restricted IP range."
  type        = string
  default     = "127.0.0.1/32"  // Default to localhost only - users must explicitly set their allowed IPs
}

variable "allowed_api_cidr" {
  description = "CIDR block allowed for Kubernetes API access"
  type        = string
  default     = "0.0.0.0/0"  // Should be restricted in production
}

variable "tags" {
  description = "Freeform tags for resources"
  type        = map(string)
  default     = {}
}
