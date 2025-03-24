/**
 * Monitoring Module for OCI Kubernetes
 * 
 * This module installs monitoring tools including:
 * - Prometheus for metrics collection
 * - Grafana for visualization
 * - Alertmanager for alerting
 */

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
  
  # Default monitoring components
  monitoring_components = {
    prometheus = true
    grafana    = true
    alertmanager = true
    node_exporter = true
    loki = var.enable_loki
  }
  
  # Chart versions - centralized for easier updates
  chart_versions = {
    prometheus_stack = var.prometheus_stack_version
    node_exporter    = var.node_exporter_version
    loki             = var.loki_version
  }
}

# Verify Kubernetes API connectivity before proceeding
resource "null_resource" "k8s_connectivity_check" {
  provisioner "local-exec" {
    command = <<-EOT
      echo "Verifying Kubernetes connectivity from monitoring module..."
      max_retries=${var.k8s_connection_timeout / var.k8s_connection_retry_interval}
      counter=0
      
      until kubectl --kubeconfig ${var.kubeconfig_path} get ns kube-system &>/dev/null; do
        sleep ${var.k8s_connection_retry_interval}
        counter=$((counter + 1))
        echo "Waiting for Kubernetes API to become available... ($counter/$max_retries)"
        
        if [ $counter -eq $max_retries ]; then
          echo "ERROR: Timed out waiting for Kubernetes API"
          exit 1
        fi
      done
      
      echo "Successfully connected to Kubernetes API from monitoring module"
    EOT
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
  
  # Ensure we've verified connectivity first
  depends_on = [
    null_resource.k8s_connectivity_check
  ]
}

# Prometheus Stack (includes Prometheus, Alertmanager and Grafana)
resource "helm_release" "prometheus_stack" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = local.chart_versions.prometheus_stack
  
  values = [
    var.custom_values != "" ? file(var.custom_values) : file("${path.module}/values/prometheus-values.yaml")
  ]

  set {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
  }
  
  # Make service monitors work cluster-wide
  set {
    name  = "prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues"
    value = false
  }
  
  set {
    name  = "prometheus.prometheusSpec.serviceMonitorSelector"
    value = "{}"
  }

  # Configure storage
  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName"
    value = var.storage_class_name
  }
  
  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
    value = var.prometheus_storage_size
  }

  # Enable Grafana persistence
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
  version    = local.chart_versions.node_exporter
  
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
  version    = local.chart_versions.loki
  
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
