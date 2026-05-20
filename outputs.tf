# Outputs are intentionally minimal. The private key, fingerprint, tenancy
# OCID, and region are NOT exported — the module pushes credentials straight
# to Kubex internally

output "user_ocid" {
  description = "OCID of the Kubex service user (existing or newly created)."
  value       = local.user_ocid
}

output "kubex_connection_id" {
  description = "Connection ID in Kubex (from save or update, whichever ran)."
  value       = local.final_connection.connectionId
}

output "kubex_connection_name" {
  description = "Connection display name in Kubex."
  value       = local.final_connection.connectionName
}

output "kubex_account_id" {
  description = "Kubex accountId for this connection (used by update mutation on re-runs)."
  value       = local.connection_exists ? local.existing_account_id : local.final_connection.connectionId
}

output "kubex_action" {
  description = "Which mutation ran: 'create' (saveOciConnection) or 'update' (updateOciConnection)."
  value       = local.connection_exists ? "update" : "create"
}

output "kubex_verify_status" {
  description = "Status returned by verifyConnectionSettings."
  value = {
    platform       = local.verify_response.platform
    status         = local.verify_response.status
    status_details = local.verify_response.statusDetails
    account_name   = local.verify_response.accountName
  }
}
