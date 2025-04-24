/**
 * Outputs for Network Module
 * 
 * Provides comprehensive information about created network resources
 * for use by dependent modules and root module outputs.
 */

#######################
# Core Resources      #
#######################

output "vcn_id" {
  description = "The OCID of the created Virtual Cloud Network"
  value       = oci_core_virtual_network.vcn.id
}

output "vcn_name" {
  description = "The display name of the created VCN"
  value       = oci_core_virtual_network.vcn.display_name
}

output "vcn_cidr" {
  description = "The CIDR block of the VCN"
  value       = oci_core_virtual_network.vcn.cidr_block
}

output "vcn_dns_label" {
  description = "The DNS label of the VCN"
  value       = oci_core_virtual_network.vcn.dns_label
}

#######################
# Gateway Resources   #
#######################

output "internet_gateway_id" {
  description = "The OCID of the Internet Gateway"
  value       = oci_core_internet_gateway.internet_gateway.id
}

output "nat_gateway_id" {
  description = "The OCID of the NAT Gateway (if created)"
  value       = try(oci_core_nat_gateway.nat_gateway[0].id, null)
}

output "service_gateway_id" {
  description = "The OCID of the Service Gateway for OCI services"
  value       = oci_core_service_gateway.service_gateway.id
}

#######################
# Subnet Resources    #
#######################

output "service_subnet_id" {
  description = "The OCID of the subnet for Kubernetes API services"
  value       = oci_core_subnet.service_subnet.id
}

output "worker_subnet_id" {
  description = "The OCID of the subnet for Kubernetes worker nodes"
  value       = oci_core_subnet.worker_subnet.id
}

output "service_subnet_cidr" {
  description = "The CIDR range of the service subnet"
  value       = oci_core_subnet.service_subnet.cidr_block
}

output "worker_subnet_cidr" {
  description = "The CIDR range of the worker subnet"
  value       = oci_core_subnet.worker_subnet.cidr_block
}

output "service_subnet_dns_label" {
  description = "The DNS label of the service subnet"
  value       = oci_core_subnet.service_subnet.dns_label
}

output "worker_subnet_dns_label" {
  description = "The DNS label of the worker subnet"
  value       = oci_core_subnet.worker_subnet.dns_label
}

#######################
# Security Resources  #
#######################

output "api_security_list_id" {
  description = "The OCID of the Kubernetes API security list"
  value       = oci_core_security_list.api_security_list.id
}

output "worker_security_list_id" {
  description = "The OCID of the worker nodes security list"
  value       = oci_core_security_list.worker_security_list.id
}

output "dhcp_options_id" {
  description = "The OCID of the DHCP options"
  value       = oci_core_dhcp_options.dhcp_options.id
}

#######################
# Network Configuration #
#######################

output "is_private_networking" {
  description = "Whether the network is configured with private networking (no public IPs on worker nodes)"
  value       = local.create_private_resources
}

output "network_configuration" {
  description = "Map of network configuration details"
  value = {
    vcn_id           = oci_core_virtual_network.vcn.id
    vcn_cidr         = oci_core_virtual_network.vcn.cidr_block
    public_route_id  = oci_core_route_table.public_route_table.id
    private_route_id = oci_core_route_table.private_route_table.id
    service_subnet = {
      id         = oci_core_subnet.service_subnet.id
      cidr_block = oci_core_subnet.service_subnet.cidr_block
      domain     = "${oci_core_subnet.service_subnet.dns_label}.${oci_core_virtual_network.vcn.dns_label}.oraclevcn.com"
    }
    worker_subnet = {
      id         = oci_core_subnet.worker_subnet.id
      cidr_block = oci_core_subnet.worker_subnet.cidr_block
      domain     = "${oci_core_subnet.worker_subnet.dns_label}.${oci_core_virtual_network.vcn.dns_label}.oraclevcn.com"
    }
  }
}

#######################
# Dependencies        #
#######################

output "subnet_dependency" {
  description = "Reference to the subnet dependency waiter resource for use in dependent modules"
  value       = null_resource.subnet_dependency_waiter
}
