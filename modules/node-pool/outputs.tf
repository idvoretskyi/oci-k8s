/**
 * Outputs for Node Pool Module
 */

output "node_pool_id" {
  description = "OCID of the created node pool"
  value       = oci_containerengine_node_pool.node_pool.id
}

output "node_pool_name" {
  description = "Name of the node pool"
  value       = oci_containerengine_node_pool.node_pool.name
}

output "node_image_id" {
  description = "Image ID used for the nodes"
  value       = oci_containerengine_node_pool.node_pool.node_source_details[0].image_id
}

output "nodes_count" {
  description = "Number of nodes in the pool"
  value       = var.node_pool_size
}
