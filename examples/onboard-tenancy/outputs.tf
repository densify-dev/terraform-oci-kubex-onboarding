output "kubex_action" {
  description = "Whether this run created or updated the Kubex connection."
  value       = module.kubex.kubex_action
}

output "kubex_connection_id" {
  value = module.kubex.kubex_connection_id
}

output "kubex_connection_name" {
  value = module.kubex.kubex_connection_name
}

output "kubex_verify_status" {
  value = module.kubex.kubex_verify_status
}

output "user_ocid" {
  description = "OCID of the OCI service user (existing or newly created)."
  value       = module.kubex.user_ocid
}
