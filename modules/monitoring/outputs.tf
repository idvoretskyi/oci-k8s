/**
 * Monitoring Module Outputs
 *
 * This file defines all outputs provided by the monitoring module
 * to help users access and interact with deployed monitoring components.
 */

output "monitoring_namespace" {
  description = "Namespace where monitoring stack is deployed"
  value       = var.namespace
}

output "prometheus_release_name" {
  description = "Release name of the deployed Prometheus stack"
  value       = helm_release.prometheus_stack.name
}

output "prometheus_stack_status" {
  description = "Status of the deployed Prometheus stack"
  value       = helm_release.prometheus_stack.status
}

output "prometheus_namespace" {
  description = "Namespace in which Prometheus stack is deployed"
  value       = var.namespace
}

output "grafana_admin_user" {
  description = "Admin username for Grafana"
  value       = "admin"
}

output "grafana_admin_password" {
  description = "The admin password for Grafana"
  value       = var.grafana_admin_password
  sensitive   = true
}

output "grafana_endpoint" {
  description = "Internal endpoint for Grafana"
  value       = "http://prometheus-grafana.${var.namespace}.svc.cluster.local:80"
}

output "alertmanager_endpoint" {
  description = "Internal endpoint for Alertmanager"
  value       = "http://prometheus-alertmanager.${var.namespace}.svc.cluster.local:9093"
}

output "loki_enabled" {
  description = "Whether Loki log collection is enabled"
  value       = var.enable_loki
}

output "loki_endpoint" {
  description = "Internal endpoint for Loki if enabled"
  value       = var.enable_loki ? "http://loki-gateway.${var.namespace}.svc.cluster.local:80" : "Loki not enabled"
}

output "tempo_enabled" {
  description = "Whether Tempo distributed tracing is enabled"
  value       = var.enable_tempo
}

output "tempo_endpoint" {
  description = "Internal endpoint for Tempo if enabled"
  value       = var.enable_tempo ? "http://tempo.${var.namespace}.svc.cluster.local:3100" : "Tempo not enabled"
}

output "dashboards_configured" {
  description = "List of dashboards configured in Grafana"
  value       = var.enable_oci_dashboards ? ["OCI Overview", "OCI Compute", "OCI Networking", "OCI Storage"] : ["Default Kubernetes dashboards"]
}

output "monitoring_port_forward_commands" {
  description = "Commands for port-forwarding to access services locally"
  value = {
    prometheus   = "kubectl -n ${var.namespace} port-forward svc/prometheus-server 9090:9090"
    grafana      = "kubectl -n ${var.namespace} port-forward svc/prometheus-grafana 3000:80"
    alertmanager = "kubectl -n ${var.namespace} port-forward svc/prometheus-alertmanager 9093:9093"
    loki         = var.enable_loki ? "kubectl -n ${var.namespace} port-forward svc/loki-gateway 3100:80" : "Loki not enabled"
    tempo        = var.enable_tempo ? "kubectl -n ${var.namespace} port-forward svc/tempo 4317:4317" : "Tempo not enabled"
  }
}

output "monitoring_resource_consumption" {
  description = "Estimated resource consumption of the monitoring stack"
  value = {
    cpu_request    = "${var.resource_quota_cpu} out of ${var.resource_quota_cpu_limit} limit"
    memory_request = "${var.resource_quota_memory} out of ${var.resource_quota_memory_limit} limit"
    storage = {
      prometheus   = var.prometheus_storage_size
      grafana      = var.grafana_storage_size
      alertmanager = var.alertmanager_storage_size
      loki         = var.enable_loki ? var.loki_storage_size : "0"
      tempo        = var.enable_tempo ? var.tempo_storage_size : "0"
    }
  }
}
