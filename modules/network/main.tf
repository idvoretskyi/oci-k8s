/**
 * Network Module for OCI Kubernetes
 * 
 * This module creates the network infrastructure for an OKE cluster including:
 * - Virtual Cloud Network (VCN)
 * - Internet Gateway
 * - Route Table
 * - Security Lists
 * - Service Subnet for K8s API
 * - Worker Subnet for K8s Nodes
 */

// Create Virtual Cloud Network (VCN)
resource "oci_core_virtual_network" "vcn" {
  compartment_id = var.compartment_id
  cidr_block     = var.vcn_cidr
  display_name   = "${var.prefix}_vcn"
  dns_label      = "${var.prefix}vcn"
  
  freeform_tags = merge(
    var.tags,
    { "ResourceType" = "VCN" }
  )
}

// Create Internet Gateway
resource "oci_core_internet_gateway" "internet_gateway" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "${var.prefix}_internet_gateway"
  
  freeform_tags = merge(
    var.tags,
    { "ResourceType" = "InternetGateway" }
  )
}

// Create Route Table
resource "oci_core_route_table" "route_table" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "${var.prefix}_route_table"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.internet_gateway.id
  }
  
  freeform_tags = merge(
    var.tags,
    { "ResourceType" = "RouteTable" }
  )
}

// Create Security List with improved rules
resource "oci_core_security_list" "security_list" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "${var.prefix}_security_list"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
    description = "Allow all outbound traffic"
  }

  // SSH access
  ingress_security_rules {
    protocol    = "6" // TCP
    source      = var.allowed_ssh_cidr
    description = "Allow SSH from trusted sources"
    
    tcp_options {
      min = 22
      max = 22
    }
  }

  // Kubernetes API access
  ingress_security_rules {
    protocol    = "6" // TCP
    source      = var.allowed_api_cidr
    description = "Allow access to Kubernetes API"
    
    tcp_options {
      min = 6443
      max = 6443
    }
  }

  // Internal cluster communication
  ingress_security_rules {
    protocol    = "all"
    source      = var.vcn_cidr
    description = "Allow all traffic inside the VCN"
  }
  
  freeform_tags = merge(
    var.tags,
    { "ResourceType" = "SecurityList" }
  )
}

// Create Service Subnet for Kubernetes API server endpoint
resource "oci_core_subnet" "service_subnet" {
  compartment_id      = var.compartment_id
  vcn_id              = oci_core_virtual_network.vcn.id
  cidr_block          = var.service_subnet_cidr
  display_name        = "${var.prefix}_service_subnet"
  security_list_ids   = [oci_core_security_list.security_list.id]
  route_table_id      = oci_core_route_table.route_table.id
  dns_label           = "${var.prefix}service"
  
  freeform_tags = merge(
    var.tags,
    { "ResourceType" = "ServiceSubnet" }
  )
}

// Create Worker Subnet for worker nodes
resource "oci_core_subnet" "worker_subnet" {
  compartment_id      = var.compartment_id
  vcn_id              = oci_core_virtual_network.vcn.id
  cidr_block          = var.worker_subnet_cidr
  display_name        = "${var.prefix}_worker_subnet"
  security_list_ids   = [oci_core_security_list.security_list.id]
  route_table_id      = oci_core_route_table.route_table.id
  dns_label           = "${var.prefix}worker"
  
  freeform_tags = merge(
    var.tags,
    { "ResourceType" = "WorkerSubnet" }
  )
}
