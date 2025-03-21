/**
 * Outputs for Monitoring Module
 */

output "prometheus_service" {
  description = "Prometheus service details"
  value = length(kubernetes_namespace.monitoring) > 0 ? {
    name      = "prometheus-kube-prometheus-prometheus"
    namespace = kubernetes_namespace.monitoring[0].metadata[0].name
    port      = 9090
  } : null
}

output "grafana_service" {
  description = "Grafana service details"
  value = length(kubernetes_namespace.monitoring) > 0 ? {
    name      = "prometheus-grafana"
    namespace = kubernetes_namespace.monitoring[0].metadata[0].name
    port      = 80
    admin_password = var.grafana_admin_password
  } : null
  sensitive = true
}

output "alertmanager_service" {
  description = "Alertmanager service details"
  value = length(kubernetes_namespace.monitoring) > 0 ? {
    name      = "prometheus-kube-prometheus-alertmanager"
    namespace = kubernetes_namespace.monitoring[0].metadata[0].name
    port      = 9093
  } : null
}

output "monitoring_namespace" {
  description = "Kubernetes namespace for monitoring"
  value       = length(kubernetes_namespace.monitoring) > 0 ? kubernetes_namespace.monitoring[0].metadata[0].name : null
}
