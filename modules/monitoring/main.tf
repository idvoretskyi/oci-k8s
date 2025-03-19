/**
 * Monitoring Module for OCI Kubernetes
 * 
 * This module installs monitoring tools including:
 * - Prometheus for metrics collection
 * - Grafana for visualization
 * - Alertmanager for alerting
 */

# Sanitize labels to conform to Kubernetes label requirements
locals {
  # Process all incoming labels to ensure they're valid for Kubernetes
  sanitized_labels = {
    for k, v in var.labels :
    k => replace(
      replace(
        lower(v),
        " ", "_"
      ),
      "[^a-z0-9_.-]", ""
    )
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.namespace
    labels = merge(
      {
        name = var.namespace
      },
      local.sanitized_labels
    )
  }
}

# Prometheus Stack (includes Prometheus, Alertmanager and Grafana)
resource "helm_release" "prometheus_stack" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = var.prometheus_stack_version
  
  values = [
    var.custom_values != "" ? file(var.custom_values) : file("${path.module}/values/prometheus-values.yaml")
  ]

  set {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
  }
  
  set {
    name  = "prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues"
    value = false
  }
  
  set {
    name  = "prometheus.prometheusSpec.serviceMonitorSelector"
    value = "{}"
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName"
    value = var.storage_class_name
  }
  
  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
    value = var.prometheus_storage_size
  }

  set {
    name  = "grafana.persistence.enabled"
    value = true
  }
  
  set {
    name  = "grafana.persistence.storageClassName"
    value = var.storage_class_name
  }
  
  set {
    name  = "grafana.persistence.size"
    value = var.grafana_storage_size
  }

  depends_on = [
    kubernetes_namespace.monitoring
  ]
}

# Node exporter for machine metrics
resource "helm_release" "node_exporter" {
  name       = "node-exporter"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-node-exporter"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = var.node_exporter_version
  
  set {
    name  = "prometheus.monitor.enabled"
    value = true
  }

  depends_on = [
    helm_release.prometheus_stack
  ]
}

# Loki for log collection (optional)
resource "helm_release" "loki_stack" {
  count      = var.enable_loki ? 1 : 0
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = var.loki_version
  
  set {
    name  = "promtail.enabled"
    value = true
  }

  set {
    name  = "loki.persistence.enabled"
    value = true
  }
  
  set {
    name  = "loki.persistence.storageClassName"
    value = var.storage_class_name
  }
  
  set {
    name  = "loki.persistence.size"
    value = var.loki_storage_size
  }
  
  depends_on = [
    helm_release.prometheus_stack
  ]
}
