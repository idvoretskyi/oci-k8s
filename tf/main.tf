provider "oci" {
  config_file_profile = var.oci_profile
  region            = var.region
}

// Create Virtual Cloud Network (VCN)
resource "oci_core_virtual_network" "vcn" {
  compartment_id = var.compartment_id
  cidr_block     = var.vcn_cidr
  display_name   = "k8s_vcn"
  // ...other configurations...
}

// Create Subnet
resource "oci_core_subnet" "subnet" {
  compartment_id      = var.compartment_id
  virtual_network_id  = oci_core_virtual_network.vcn.id
  cidr_block          = var.subnet_cidr
  display_name        = "k8s_subnet"
  // ...other configurations...
}

// Create OKE Cluster
resource "oci_containerengine_cluster" "oke_cluster" {
  compartment_id = var.compartment_id
  name           = "oci-k8s-cluster"
  // ...existing code...
}

// Create Node Pool with ARM workers for cost-effectiveness
resource "oci_containerengine_node_pool" "node_pool" {
  compartment_id = var.compartment_id
  cluster_id     = oci_containerengine_cluster.oke_cluster.id
  name           = "arm-node-pool"
  node_config_details {
    // ...existing code...
    // Specify the ARM machine shape (example: "VM.Standard.E2.ARM")
    size = var.node_pool_size
  }
  node_shape = "VM.Standard.E2.ARM"
  // ...other configurations...
}
