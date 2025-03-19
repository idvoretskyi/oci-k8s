/**
 * Variables for Monitoring Module
 */

variable "namespace" {
  description = "Kubernetes namespace for monitoring tools"
  type        = string
  default     = "monitoring"
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "prometheus_stack_version" {
  description = "Version of Prometheus Stack Helm chart"
  type        = string
  default     = "45.7.1"  # Update to latest stable version as needed
}

variable "node_exporter_version" {
  description = "Version of Node Exporter Helm chart"
  type        = string
  default     = "4.3.0"  # Update to latest stable version as needed
}

variable "loki_version" {
  description = "Version of Loki Stack Helm chart"
  type        = string
  default     = "2.9.9"  # Update to latest stable version as needed
}

variable "custom_values" {
  description = "Path to custom values file for Prometheus Stack"
  type        = string
  default     = ""
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
  default     = "admin"  # Should be overridden in production
  sensitive   = true
}

variable "storage_class_name" {
  description = "Storage class name for persistent volumes"
  type        = string
  default     = "oci-bv"  # OCI Block Volume storage class
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

variable "loki_storage_size" {
  description = "Storage size for Loki"
  type        = string
  default     = "10Gi"
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
