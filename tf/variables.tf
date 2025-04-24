/**
 * Variables for the OCI Kubernetes project with OpenTofu
 */

# Authentication variables - will be read from config if not specified
variable "oci_profile" {
  description = "OCI CLI profile name"
  type        = string
  default     = "DEFAULT"
}

variable "region" {
  description = "OCI region (can be set using TF_VAR_region environment variable with OpenTofu)"
  type        = string
}

variable "compartment_id" {
  description = "Compartment OCID"
  type        = string
}

variable "user_ocid" {
  description = "OCID of the user"
  type        = string
  default     = null
}

variable "fingerprint" {
  description = "Fingerprint of the API key"
  type        = string
  default     = null
}

variable "private_key_path" {
  description = "Path to the private key file"
  type        = string
  default     = "~/.oci/oci_api_key.pem"
}

variable "private_key_password" {
  description = "Password for the private key, if it's encrypted"
  type        = string
  default     = null
  sensitive   = true
}

# General configuration
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "username" {
  description = "Username to be used as a prefix for resources. If not provided, will use the current system username."
  type        = string
  default     = null  # Will be dynamically determined if not set
}

variable "resource_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "k8s"
}

# Network configuration
variable "vcn_cidr" {
  description = "CIDR block for the VCN"
  type        = string
  default     = "10.0.0.0/16"
}

variable "service_subnet_cidr" {
  description = "CIDR block for the service subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "worker_subnet_cidr" {
  description = "CIDR block for the worker node subnet"
  type        = string
  default     = "10.0.2.0/24"
}

# Kubernetes configuration
variable "kubernetes_version" {
  description = "Kubernetes version for the OKE cluster"
  type        = string
  default     = "v1.32.1"
}

variable "enable_kubernetes_dashboard" {
  description = "Whether to enable the Kubernetes dashboard"
  type        = bool
  default     = true
}

variable "enable_public_endpoint" {
  description = "Whether to enable public IP for the cluster endpoint"
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

# Kubernetes API connection settings
variable "k8s_connection_max_retries" {
  description = "Maximum number of connection attempts to Kubernetes API"
  type        = number
  default     = 60
}

variable "k8s_connection_retry_interval" {
  description = "Seconds to wait between Kubernetes API connection attempts"
  type        = number
  default     = 10
}

# Node pool configuration
variable "node_pool_size" {
  description = "Number of nodes in the node pool"
  type        = number
  default     = 3
}

variable "node_shape" {
  description = "Shape of the nodes in the pool"
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "node_image_id" {
  description = "The OCID of the image to use for node pool instances"
  type        = string
  default     = null
}

variable "availability_domain" {
  description = "Availability domain"
  type        = string
  default     = null
}

variable "node_memory_in_gbs" {
  description = "Amount of memory in GBs for flex shapes"
  type        = number
  default     = 6
}

variable "node_ocpus" {
  description = "Number of OCPUs for flex shapes"
  type        = number
  default     = 1
}

# Monitoring configuration
variable "enable_monitoring" {
  description = "Whether to enable the monitoring stack (Prometheus, Grafana, Alertmanager)"
  type        = bool
  default     = true
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
  # Default removed for security - must be explicitly set by the user
  sensitive   = true
}

variable "prometheus_storage_size" {
  description = "Storage size for Prometheus"
  type        = string
  default     = "10Gi"
}

variable "grafana_storage_size" {
  description = "Storage size for Grafana"
  type        = string
  default     = "5Gi"
}

variable "enable_loki" {
  description = "Whether to enable Loki for log collection"
  type        = bool
  default     = true
}

variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

# Pod Security configuration
variable "enable_pod_security_admission" {
  description = "Whether to enable Pod Security Admission Controller (modern replacement for deprecated Pod Security Policies)"
  type        = bool
  default     = true
}
