# Simple ARM OKE Cluster Configuration
# Based on Oracle's ARM Kubernetes tutorial

# Get tenancy and user info from OCI config
data "external" "oci_config" {
  program = ["bash", "-c", "grep -E '^(tenancy|user)=' ~/.oci/config | sed 's/=/\":\"/' | sed 's/^/\"/' | sed 's/$/\",/' | tr -d '\n' | sed 's/,$//' | sed 's/^/{/' | sed 's/$/}/'"]
}

locals {
  tenancy_ocid   = data.external.oci_config.result.tenancy
  user_ocid      = data.external.oci_config.result.user
  compartment_id = coalesce(var.compartment_ocid, local.tenancy_ocid)
}

# Get availability domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = local.compartment_id
}

# Get latest ARM-compatible Oracle Linux image
data "oci_core_images" "arm_images" {
  compartment_id           = local.compartment_id
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# Create VCN with simple configuration
resource "oci_core_vcn" "vcn" {
  compartment_id = local.compartment_id
  cidr_blocks    = ["10.0.0.0/16"]
  display_name   = "${var.cluster_name}-vcn"
  dns_label      = "armokecluster"
}

# Internet gateway for public access
resource "oci_core_internet_gateway" "igw" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.cluster_name}-igw"
}

# NAT gateway for private subnet outbound access
resource "oci_core_nat_gateway" "ngw" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.cluster_name}-ngw"
}

# Route table for public subnet
resource "oci_core_route_table" "public_rt" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.cluster_name}-public-rt"
  
  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.igw.id
  }
}

# Route table for private subnet
resource "oci_core_route_table" "private_rt" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.cluster_name}-private-rt"
  
  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_nat_gateway.ngw.id
  }
}

# Security list with minimal required rules for OKE
resource "oci_core_security_list" "oke_sl" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.cluster_name}-oke-sl"
  
  # Allow all egress
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }
  
  # Allow all traffic within VCN
  ingress_security_rules {
    protocol = "all"
    source   = "10.0.0.0/16"
  }
  
  # Allow Kubernetes API access
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 6443
      max = 6443
    }
  }
  
  # Allow ICMP for path discovery
  ingress_security_rules {
    protocol = "1"
    source   = "0.0.0.0/0"
    icmp_options {
      type = 3
      code = 4
    }
  }
}

# Public subnet for load balancers and API endpoint
resource "oci_core_subnet" "public_subnet" {
  compartment_id             = local.compartment_id
  vcn_id                     = oci_core_vcn.vcn.id
  cidr_block                 = "10.0.1.0/24"
  display_name               = "${var.cluster_name}-public"
  dns_label                  = "public"
  route_table_id             = oci_core_route_table.public_rt.id
  security_list_ids          = [oci_core_security_list.oke_sl.id]
  prohibit_public_ip_on_vnic = false
}

# Private subnet for worker nodes (recommended by Oracle)
resource "oci_core_subnet" "private_subnet" {
  compartment_id             = local.compartment_id
  vcn_id                     = oci_core_vcn.vcn.id
  cidr_block                 = "10.0.2.0/24"
  display_name               = "${var.cluster_name}-private"
  dns_label                  = "private"
  route_table_id             = oci_core_route_table.private_rt.id
  security_list_ids          = [oci_core_security_list.oke_sl.id]
  prohibit_public_ip_on_vnic = true
}

# OKE Cluster - ARM optimized
resource "oci_containerengine_cluster" "arm_cluster" {
  compartment_id     = local.compartment_id
  kubernetes_version = var.kubernetes_version
  name               = var.cluster_name
  vcn_id             = oci_core_vcn.vcn.id
  
  endpoint_config {
    is_public_ip_enabled = true
    subnet_id            = oci_core_subnet.public_subnet.id
  }
  
  options {
    service_lb_subnet_ids = [oci_core_subnet.public_subnet.id]
    
    add_ons {
      is_kubernetes_dashboard_enabled = false
      is_tiller_enabled               = false
    }
    
    kubernetes_network_config {
      pods_cidr     = "10.244.0.0/16"
      services_cidr = "10.96.0.0/16"
    }
  }
}

# ARM Node Pool - simplified configuration
resource "oci_containerengine_node_pool" "arm_pool" {
  compartment_id     = local.compartment_id
  cluster_id         = oci_containerengine_cluster.arm_cluster.id
  kubernetes_version = var.kubernetes_version
  name               = "${var.cluster_name}-arm-pool"
  node_shape         = "VM.Standard.A1.Flex"
  
  node_config_details {
    size = var.node_count
    
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
      subnet_id           = oci_core_subnet.private_subnet.id
    }
  }
  
  node_shape_config {
    memory_in_gbs = var.node_memory_gb
    ocpus         = var.node_ocpus
  }
  
  node_source_details {
    source_type             = "IMAGE"
    image_id                = data.oci_core_images.arm_images.images[0].id
    boot_volume_size_in_gbs = 50
  }
  
  # ARM architecture label
  initial_node_labels {
    key   = "kubernetes.io/arch"
    value = "arm64"
  }
  
  # ARM node pool label
  initial_node_labels {
    key   = "node.kubernetes.io/instance-type"
    value = "arm64"
  }
}