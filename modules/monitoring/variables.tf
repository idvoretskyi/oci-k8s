/**
 * Monitoring Module Variables
 * 
 * This file defines all variables used by the monitoring module to configure
 * the observability stack for OCI Kubernetes clusters.
 */

#######################
# Core Configuration  #
#######################

variable "namespace" {
  description = "Namespace to deploy monitoring components"
  type        = string
  default     = "monitoring"
}

variable "labels" {
  description = "Additional labels to apply to all monitoring resources"
  type        = map(string)
  default     = {}
}

variable "kubeconfig_path" {
  description = "Path to the kubeconfig file for connecting to the cluster"
  type        = string
  default     = "~/.kube/config"
}

variable "k8s_connection_timeout" {
  description = "Timeout in seconds for Kubernetes API connection"
  type        = number
  default     = 300 # 5 minutes
}

variable "k8s_connection_retry_interval" {
  description = "Time in seconds between Kubernetes API connection retries"
  type        = number
  default     = 10
}

variable "helm_timeout" {
  description = "Timeout for Helm operations in seconds"
  type        = number
  default     = 600 # 10 minutes
}

#######################
# Storage Settings    #
#######################

variable "storage_class_name" {
  description = "Storage class name to be used for all persistent volumes"
  type        = string
  default     = "oci-bv" # Default OCI Block Volume storage class
}

variable "prometheus_storage_size" {
  description = "Storage size for Prometheus"
  type        = string
  default     = "50Gi"
}

variable "grafana_storage_size" {
  description = "Storage size for Grafana"
  type        = string
  default     = "10Gi"
}

variable "alertmanager_storage_size" {
  description = "Storage size for Alertmanager"
  type        = string
  default     = "10Gi"
}

variable "loki_storage_size" {
  description = "Storage size for Loki logs"
  type        = string
  default     = "50Gi"
}

variable "tempo_storage_size" {
  description = "Storage size for Tempo persistence"
  type        = string
  default     = "10Gi"
}

#######################
# Component Versions  #
#######################

variable "prometheus_stack_version" {
  description = "Version of the Prometheus operator Helm chart"
  type        = string
  default     = "51.10.0" # Updated to latest stable version as of April 2025
}

variable "node_exporter_version" {
  description = "Version of the node exporter Helm chart"
  type        = string
  default     = "4.24.0" # Updated to latest stable version as of April 2025
}

variable "loki_version" {
  description = "Version of the Loki stack Helm chart"
  type        = string
  default     = "5.8.12" # Updated to latest stable version as of April 2025
}

variable "tempo_version" {
  description = "Version of the Tempo Helm chart"
  type        = string
  default     = "1.7.1" # Updated to latest stable version as of April 2025
}

#######################
# Data Retention      #
#######################

variable "prometheus_retention_period" {
  description = "Data retention period for Prometheus (format: 15d, 6h, etc)"
  type        = string
  default     = "15d" # 15 days
}

variable "loki_retention_period" {
  description = "Data retention period for Loki logs in hours"
  type        = string
  default     = "744h" # 31 days
}

variable "tempo_retention_period" {
  description = "Data retention period for Tempo traces in hours"
  type        = string
  default     = "168h" # 7 days
}

#######################
# Component Toggles   #
#######################

variable "enable_resource_quotas" {
  description = "Enable resource quotas for the monitoring namespace"
  type        = bool
  default     = true
}

variable "enable_loki" {
  description = "Enable Loki for log collection"
  type        = bool
  default     = false
}

variable "enable_tempo" {
  description = "Whether to install Tempo for distributed tracing"
  type        = bool
  default     = false
}

variable "enable_oci_dashboards" {
  description = "Enable OCI-specific dashboards in Grafana"
  type        = bool
  default     = true
}

#######################
# Grafana Settings    #
#######################

variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
  default     = "admin" # Should be overridden in production
  sensitive   = true
}

variable "grafana_domain" {
  description = "Domain name for Grafana"
  type        = string
  default     = ""
}

variable "custom_dashboards_path" {
  description = "Path to directory containing custom Grafana dashboard JSON files"
  type        = string
  default     = ""
}

#######################
# Resource Quotas     #
#######################

variable "resource_quota_cpu" {
  description = "CPU request quota for monitoring namespace"
  type        = string
  default     = "6000m" # 6 cores
}

variable "resource_quota_memory" {
  description = "Memory request quota for monitoring namespace"
  type        = string
  default     = "12Gi"
}

variable "resource_quota_cpu_limit" {
  description = "CPU limit quota for monitoring namespace"
  type        = string
  default     = "12000m" # 12 cores
}

variable "resource_quota_memory_limit" {
  description = "Memory limit quota for monitoring namespace"
  type        = string
  default     = "24Gi"
}

variable "resource_quota_pod_count" {
  description = "Maximum number of pods in monitoring namespace"
  type        = string
  default     = "30"
}

#######################
# Advanced Settings   #
#######################

variable "custom_prometheus_values" {
  description = "Path to custom values file for Prometheus Helm chart"
  type        = string
  default     = ""
}

variable "custom_loki_values" {
  description = "Path to custom values file for Loki Helm chart"
  type        = string
  default     = ""
}

variable "custom_tempo_values" {
  description = "Path to custom values file for Tempo Helm chart"
  type        = string
  default     = ""
}

variable "alert_receivers" {
  description = "List of alert receivers configuration for Alertmanager"
  type        = list(string)
  default     = []
}
