output "single_node_policy_id" {
  description = "ID of the single-node cluster policy"
  value       = databricks_cluster_policy.single_node.id
}

output "standard_policy_id" {
  description = "ID of the standard multi-node cluster policy"
  value       = databricks_cluster_policy.standard.id
}

output "shared_instance_pool_id" {
  description = "ID of the shared instance pool"
  value       = databricks_instance_pool.shared.id
}
