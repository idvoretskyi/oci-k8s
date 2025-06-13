# ARM OKE Cluster Configuration
# Based on Oracle's straightforward ARM deployment approach

# OCI region - UK South (London) has good ARM availability
region = "uk-london-1"

# Compartment will be read from ~/.oci/config if not specified
# compartment_ocid = "your-compartment-ocid-here"

# Path to your private key for API access
private_key_path = "/Users/idv/.oci/oci_api_key.pem"

# ARM Kubernetes cluster configuration
cluster_name = "simple-arm-oke"
kubernetes_version = "v1.33.0"

# ARM node configuration - start small for testing
node_count = 1
node_memory_gb = 6
node_ocpus = 1