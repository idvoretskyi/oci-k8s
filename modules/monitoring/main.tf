/**
 * Monitoring Module for OCI Kubernetes
 * 
 * This module provides comprehensive monitoring and observability for OKE clusters:
 * - Prometheus for metrics collection and alerting
 * - Grafana for visualization and dashboarding
 * - Alertmanager for alert management and routing
 * - Node-exporter for system metrics
 * - Loki for log aggregation (optional)
 * - Tempo for distributed tracing (optional)
 * - Kubernetes service monitors for automatic scraping
 */

#######################
# Local Variables     #
#######################

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

  # Enhanced monitoring components configuration
  monitoring_components = {
    prometheus    = true
    grafana       = true
    alertmanager  = true
    node_exporter = true
    loki          = var.enable_loki
    tempo         = var.enable_tempo
  }

  # Chart versions - centralized for easier updates
  chart_versions = {
    prometheus_stack = var.prometheus_stack_version
    node_exporter    = var.node_exporter_version
    loki             = var.loki_version
    tempo            = var.tempo_version
  }

  # Common labels for all monitoring resources
  common_labels = merge(
    local.sanitized_labels,
    {
      "app.kubernetes.io/managed-by"  = "opentofu"
      "app.kubernetes.io/part-of"     = "monitoring-stack"
      "kubernetes.io/cluster-service" = "true"
    }
  )

  # Default retention settings
  retention = {
    prometheus = var.prometheus_retention_period
    loki       = var.loki_retention_period
    tempo      = var.tempo_retention_period
  }

  # Load values files with fallbacks to module defaults
  prometheus_values = var.custom_prometheus_values != "" ? file(var.custom_prometheus_values) : file("${path.module}/values/prometheus-values.yaml")
  loki_values       = var.custom_loki_values != "" ? file(var.custom_loki_values) : file("${path.module}/values/loki-values.yaml")
  tempo_values      = var.custom_tempo_values != "" ? file(var.custom_tempo_values) : file("${path.module}/values/tempo-values.yaml")
}

#######################
# Kubernetes Resources #
#######################

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

# Create dedicated namespace for monitoring stack
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.namespace
    labels = merge(
      {
        name = var.namespace
      },
      local.common_labels
    )

    annotations = {
      "opentofu.io/module"             = "monitoring"
      "oci.oraclecloud.com/created-by" = "oci-k8s-opentofu-module"
    }
  }

  # Ensure we've verified connectivity first
  depends_on = [
    null_resource.k8s_connectivity_check
  ]
}

# Create resource quotas to prevent monitoring from consuming all cluster resources
resource "kubernetes_resource_quota" "monitoring_quota" {
  count = var.enable_resource_quotas ? 1 : 0

  metadata {
    name      = "monitoring-quota"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  spec {
    hard = {
      "requests.cpu"    = var.resource_quota_cpu
      "requests.memory" = var.resource_quota_memory
      "limits.cpu"      = var.resource_quota_cpu_limit
      "limits.memory"   = var.resource_quota_memory_limit
      "pods"            = var.resource_quota_pod_count
    }
  }
}

#######################
# Prometheus Stack    #
#######################

# Add Helm repositories
resource "helm_release" "prometheus_stack" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = local.chart_versions.prometheus_stack
  timeout    = var.helm_timeout

  values = [
    local.prometheus_values
  ]

  # Grafana admin credentials
  set {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
  }

  # Set custom domain for Grafana if specified
  set {
    name  = "grafana.domain"
    value = var.grafana_domain != "" ? var.grafana_domain : "grafana.local"
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

  # Set retention period
  set {
    name  = "prometheus.prometheusSpec.retention"
    value = local.retention.prometheus
  }

  # Configure Prometheus storage
  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName"
    value = var.storage_class_name
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
    value = var.prometheus_storage_size
  }

  # Configure Alertmanager storage
  set {
    name  = "alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.storageClassName"
    value = var.storage_class_name
  }

  set {
    name  = "alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.resources.requests.storage"
    value = var.alertmanager_storage_size
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

  # Add OCI dashboards
  set {
    name  = "grafana.dashboards.oci.enabled"
    value = var.enable_oci_dashboards
  }

  # Configure security context for components
  set {
    name  = "prometheus.prometheusSpec.securityContext.runAsNonRoot"
    value = "true"
  }

  set {
    name  = "prometheus.prometheusSpec.securityContext.runAsUser"
    value = "1000"
  }

  # Configure alertmanager settings if alert receivers are specified
  dynamic "set" {
    for_each = length(var.alert_receivers) > 0 ? [1] : []
    content {
      name  = "alertmanager.config.receivers[0].name"
      value = var.alert_receivers[0]  # Use the first element directly instead of joining
    }
  }

  depends_on = [
    kubernetes_namespace.monitoring,
    kubernetes_resource_quota.monitoring_quota
  ]
}

#######################
# Node Exporter      #
#######################

# Node exporter for system metrics
resource "helm_release" "node_exporter" {
  name       = "node-exporter"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-node-exporter"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = local.chart_versions.node_exporter
  timeout    = var.helm_timeout

  # Enable automatic discovery by Prometheus
  set {
    name  = "prometheus.monitor.enabled"
    value = true
  }

  # Add pod security context
  set {
    name  = "podSecurityContext.runAsNonRoot"
    value = true
  }

  set {
    name  = "podSecurityContext.runAsUser"
    value = 65534 # nobody user
  }

  depends_on = [
    helm_release.prometheus_stack
  ]
}

#######################
# Loki for Logging    #
#######################

# Loki for log collection (optional)
resource "helm_release" "loki_stack" {
  count      = var.enable_loki ? 1 : 0
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = local.chart_versions.loki
  timeout    = var.helm_timeout

  values = [
    local.loki_values
  ]

  # Enable Promtail for log collection
  set {
    name  = "promtail.enabled"
    value = true
  }

  # Configure Promtail security context
  set {
    name  = "promtail.securityContext.readOnlyRootFilesystem"
    value = true
  }

  # Enable persistence for Loki
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

  # Configure Loki retention period
  set {
    name  = "loki.config.table_manager.retention_deletes_enabled"
    value = true
  }

  set {
    name  = "loki.config.table_manager.retention_period"
    value = local.retention.loki
  }

  depends_on = [
    helm_release.prometheus_stack
  ]
}

#######################
# Tempo for Tracing   #
#######################

# Tempo for distributed tracing (optional)
resource "helm_release" "tempo" {
  count      = var.enable_tempo ? 1 : 0
  name       = "tempo"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "tempo"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = local.chart_versions.tempo
  timeout    = var.helm_timeout

  values = [
    local.tempo_values
  ]

  # Enable persistence for Tempo with proper storage configuration
  set {
    name  = "tempo.storage.trace.backend"
    value = "file"
  }

  set {
    name  = "tempo.storage.trace.local.path"
    value = "/var/tempo/traces"
  }

  set {
    name  = "persistence.enabled"
    value = true
  }

  set {
    name  = "persistence.storageClassName"
    value = var.storage_class_name
  }

  set {
    name  = "persistence.size"
    value = var.tempo_storage_size
  }

  # Configure retention
  set {
    name  = "tempo.retention"
    value = local.retention.tempo
  }

  # Add security context
  set {
    name  = "securityContext.runAsNonRoot"
    value = true
  }

  set {
    name  = "securityContext.runAsUser"
    value = "1000"
  }

  # Automatically configure Grafana data source if enabled
  set {
    name  = "serviceMonitor.enabled"
    value = true
  }

  depends_on = [
    helm_release.prometheus_stack
  ]
}

# Create ConfigMap for Tempo-Grafana integration when both are enabled
resource "kubernetes_config_map" "tempo_grafana_integration" {
  count = var.enable_tempo ? 1 : 0

  metadata {
    name      = "tempo-grafana-datasource"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels = merge(
      local.common_labels,
      {
        "grafana_datasource" = "1"
      }
    )
  }

  data = {
    "tempo-datasource.yaml" = <<-EOT
      apiVersion: 1
      datasources:
      - name: Tempo
        type: tempo
        access: proxy
        orgId: 1
        url: http://tempo.${kubernetes_namespace.monitoring.metadata[0].name}.svc.cluster.local:3100
        isDefault: false
        version: 1
        editable: false
        uid: tempo
        jsonData:
          httpMethod: GET
          tracesToLogs:
            datasourceUid: loki
            tags: ['job', 'namespace', 'pod']
            mappedTags: [{ key: 'service.name', value: 'service' }]
            mapTagNamesEnabled: false
            spanStartTimeShift: '-1h'
            spanEndTimeShift: '1h'
            filterByTraceID: true
            filterBySpanID: false
    EOT
  }

  depends_on = [
    helm_release.tempo,
    helm_release.prometheus_stack
  ]
}

#######################
# Monitoring Dashboard #
#######################

# Deploy a ConfigMap with dashboard descriptions
resource "kubernetes_config_map" "monitoring_overview" {
  metadata {
    name      = "monitoring-overview"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels = merge(
      local.common_labels,
      {
        "app.kubernetes.io/name" = "monitoring-overview"
      }
    )
  }

  data = {
    "README.md" = <<-EOT
      # Monitoring Stack Overview
      
      This monitoring stack includes the following components:
      
      ## Core Components
      
      * **Prometheus**: ${local.monitoring_components.prometheus ? "Enabled" : "Disabled"}
        - UI: http://prometheus-server.${var.namespace}.svc:9090
        - Storage: ${var.prometheus_storage_size}
        - Retention: ${local.retention.prometheus}
      
      * **Grafana**: ${local.monitoring_components.grafana ? "Enabled" : "Disabled"}
        - UI: http://grafana.${var.namespace}.svc:3000
        - Admin user: admin
        - Storage: ${var.grafana_storage_size}
      
      * **Alertmanager**: ${local.monitoring_components.alertmanager ? "Enabled" : "Disabled"}
        - UI: http://alertmanager-operated.${var.namespace}.svc:9093
        - Storage: ${var.alertmanager_storage_size}
      
      ## Additional Components
      
      * **Node Exporter**: ${local.monitoring_components.node_exporter ? "Enabled" : "Disabled"}
        - Metrics endpoint: http://node-exporter.${var.namespace}.svc:9100/metrics
      
      * **Loki (Log Aggregation)**: ${local.monitoring_components.loki ? "Enabled" : "Disabled"}
        - API endpoint: http://loki.${var.namespace}.svc:3100
        - Storage: ${local.monitoring_components.loki ? var.loki_storage_size : "N/A"}
        - Retention: ${local.monitoring_components.loki ? local.retention.loki : "N/A"}
      
      * **Tempo (Distributed Tracing)**: ${local.monitoring_components.tempo ? "Enabled" : "Disabled"}
        - API endpoint: http://tempo.${var.namespace}.svc:3100
        - Storage: ${local.monitoring_components.tempo ? var.tempo_storage_size : "N/A"}
        - Retention: ${local.monitoring_components.tempo ? local.retention.tempo : "N/A"}
      
      ## Accessing Dashboards
      
      To access Grafana dashboards:
      
      1. Forward the port: `kubectl port-forward -n ${var.namespace} svc/grafana 3000:3000`
      2. Open browser at: `http://localhost:3000`
      3. Login with admin / <password>
      
      ## Custom Dashboards
      
      Custom dashboards can be added through Grafana UI or with ConfigMaps using
      the label selector: `grafana_dashboard: "1"`
      
      ## Monitoring Stack Maintenance
      
      Version info:
      - Prometheus Stack: ${local.chart_versions.prometheus_stack}
      - Node Exporter: ${local.chart_versions.node_exporter}
      - Loki: ${local.chart_versions.loki}
      - Tempo: ${local.chart_versions.tempo}
    EOT
  }

  depends_on = [
    helm_release.prometheus_stack,
    helm_release.node_exporter,
    helm_release.loki_stack,
    helm_release.tempo
  ]
}

# Import custom dashboards if directory is specified
resource "null_resource" "import_custom_dashboards" {
  count = var.custom_dashboards_path != "" ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      echo "Importing custom Grafana dashboards from ${var.custom_dashboards_path}"
      
      # Ensure kubeconfig is available
      KUBECONFIG=${var.kubeconfig_path}
      
      # Create ConfigMaps for each JSON dashboard file
      for dashboard in ${var.custom_dashboards_path}/*.json; do
        if [ -f "$dashboard" ]; then
          basename=$(basename "$dashboard" .json)
          sanitized=$(echo "$basename" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
          
          echo "Importing dashboard: $basename"
          
          kubectl --kubeconfig $KUBECONFIG create configmap "grafana-dashboard-$sanitized" \
            --namespace ${kubernetes_namespace.monitoring.metadata[0].name} \
            --from-file="dashboard.json=$dashboard" \
            --dry-run=client -o yaml | \
            kubectl --kubeconfig $KUBECONFIG apply -f -
            
          # Add the special label that Grafana operator looks for
          kubectl --kubeconfig $KUBECONFIG label configmap "grafana-dashboard-$sanitized" \
            --namespace ${kubernetes_namespace.monitoring.metadata[0].name} \
            grafana_dashboard="1" --overwrite
        fi
      done
      
      echo "Custom dashboards import completed"
    EOT
  }

  # Trigger this resource if the path changes
  triggers = {
    dashboard_path = var.custom_dashboards_path
  }

  depends_on = [
    helm_release.prometheus_stack
  ]
}
