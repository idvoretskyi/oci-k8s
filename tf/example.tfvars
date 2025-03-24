# Oracle Cloud Infrastructure settings
region          = "uk-london-1"
compartment_id  = "ocid1.tenancy.oc1..exampleocid"

# Resource naming
resource_prefix = "k8s"
environment     = "dev"

# Network configuration
vcn_cidr            = "10.0.0.0/16"
service_subnet_cidr = "10.0.1.0/24"
worker_subnet_cidr  = "10.0.2.0/24"

# Kubernetes cluster configuration
kubernetes_version    = "v1.32.1"
enable_public_endpoint = true
pods_cidr             = "10.244.0.0/16"
services_cidr         = "10.96.0.0/16"

# Node pool configuration
node_pool_size    = 3
node_shape        = "VM.Standard.A1.Flex"
node_memory_in_gbs = 6
node_ocpus        = 1

# Monitoring configuration
enable_monitoring       = true
grafana_admin_password  = "securePassword123"  # Change this!
prometheus_storage_size = "10Gi"
grafana_storage_size    = "5Gi"
enable_loki             = true

# Kubernetes connection settings
kubeconfig_path = "~/.kube/config"
k8s_connection_max_retries = 60
k8s_connection_retry_interval = 10
