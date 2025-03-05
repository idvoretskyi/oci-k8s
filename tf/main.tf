provider "oci" {
  # Use defaults from ~/.oci/config
}

// Create Virtual Cloud Network (VCN)
resource "oci_core_virtual_network" "vcn" {
  compartment_id = var.compartment_id
  cidr_block     = var.vcn_cidr
  display_name   = "k8s_vcn"
  dns_label      = "k8svcn"
}

// Create Internet Gateway
resource "oci_core_internet_gateway" "internet_gateway" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "k8s_internet_gateway"
}

// Create Route Table
resource "oci_core_route_table" "route_table" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "k8s_route_table"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.internet_gateway.id
  }
}

// Create Security List
resource "oci_core_security_list" "security_list" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "k8s_security_list"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  ingress_security_rules {
    protocol = "6" // TCP
    source   = "0.0.0.0/0"
    
    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    protocol = "6" // TCP
    source   = "0.0.0.0/0"
    
    tcp_options {
      min = 6443
      max = 6443
    }
  }

  ingress_security_rules {
    protocol = "all"
    source   = var.vcn_cidr
  }
}

// Create Subnet
resource "oci_core_subnet" "subnet" {
  compartment_id      = var.compartment_id
  vcn_id              = oci_core_virtual_network.vcn.id
  cidr_block          = var.subnet_cidr
  display_name        = "k8s_subnet"
  security_list_ids   = [oci_core_security_list.security_list.id]
  route_table_id      = oci_core_route_table.route_table.id
  dns_label           = "k8ssubnet"
}

// Create OKE Cluster
resource "oci_containerengine_cluster" "oke_cluster" {
  compartment_id     = var.compartment_id
  kubernetes_version = var.kubernetes_version
  name               = "oci-arm-k8s-cluster"
  vcn_id             = oci_core_virtual_network.vcn.id
  
  options {
    service_lb_subnet_ids = [oci_core_subnet.subnet.id]
    
    add_ons {
      is_kubernetes_dashboard_enabled = true
      is_tiller_enabled               = false
    }
    
    kubernetes_network_config {
      pods_cidr     = "10.244.0.0/16"
      services_cidr = "10.96.0.0/16"
    }
  }

  endpoint_config {
    subnet_id            = oci_core_subnet.subnet.id
    is_public_ip_enabled = true
  }
}

// Create Node Pool with ARM workers
resource "oci_containerengine_node_pool" "node_pool" {
  compartment_id     = var.compartment_id
  cluster_id         = oci_containerengine_cluster.oke_cluster.id
  kubernetes_version = var.kubernetes_version
  name               = "arm-node-pool"
  node_shape         = "VM.Standard.A1.Flex"
  
  node_source_details {
    image_id    = var.node_image_id
    source_type = "IMAGE"
  }
  
  node_config_details {
    placement_configs {
      availability_domain = var.availability_domain
      subnet_id           = oci_core_subnet.subnet.id
    }
    size = var.node_pool_size
  }
  
  node_shape_config {
    memory_in_gbs = 6
    ocpus         = 1
  }

  initial_node_labels {
    key   = "name"
    value = "arm-node-pool"
  }
}
