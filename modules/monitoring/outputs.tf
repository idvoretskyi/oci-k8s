/**
 * Outputs for Monitoring Module
 */

output "prometheus_service" {
  description = "Prometheus service details"
  value = {
    name      = "prometheus-kube-prometheus-prometheus"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    port      = 9090
  }
}

output "grafana_service" {
  description = "Grafana service details"
  value = {
    name      = "prometheus-grafana"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    port      = 80
    admin_password = var.grafana_admin_password
  }
  sensitive = true
}

output "alertmanager_service" {
  description = "Alertmanager service details"
  value = {
    name      = "prometheus-kube-prometheus-alertmanager"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    port      = 9093
  }
}

output "monitoring_namespace" {
  description = "Kubernetes namespace for monitoring"
  value = kubernetes_namespace.monitoring.metadata[0].name
}
