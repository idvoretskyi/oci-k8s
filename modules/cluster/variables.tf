/**
 * Variables for Cluster Module
 */

variable "compartment_id" {
  description = "The OCID of the compartment where resources will be created"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the OKE cluster"
  type        = string
}

variable "cluster_name" {
  description = "Name of the OKE cluster"
  type        = string
  default     = "oci-k8s-cluster"
}

variable "vcn_id" {
  description = "The OCID of the VCN where the cluster will be created"
  type        = string
}

variable "service_subnet_id" {
  description = "The OCID of the subnet for Kubernetes API and Service LBs"
  type        = string
}

variable "enable_kubernetes_dashboard" {
  description = "Whether to enable the Kubernetes dashboard"
  type        = bool
  default     = true
}

variable "pods_cidr" {
  description = "CIDR block for Kubernetes pods"
  type        = string
  default     = "10.244.0.0/16"
}

variable "services_cidr" {
  description = "CIDR block for Kubernetes services"
  type        = string
  default     = "10.96.0.0/16"
}

variable "enable_public_endpoint" {
  description = "Whether to enable public IP for the cluster endpoint"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Freeform tags for resources"
  type        = map(string)
  default     = {}
}

variable "subnet_dependency" {
  description = "Dependency reference for subnet resources"
  type        = any
  default     = null
}

# Note: Pod Security Policy is deprecated in Kubernetes v1.21+ and removed in v1.25+
# Use Pod Security Standards instead with appropriate admission controllers
