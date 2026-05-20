data "http" "authorize" {
  url    = "${var.kubex_api_base_url}/api/v2/authorize"
  method = "POST"

  request_headers = {
    "Accept"       = "application/json"
    "Content-Type" = "application/json"
  }

  request_body = jsonencode({
    userName = var.kubex_username
    pwd      = var.kubex_password
  })

  lifecycle {
    postcondition {
      condition = (
        self.status_code == 200
        && try(jsondecode(self.response_body).apiToken, null) != null
      )
      error_message = "Kubex auth failed (HTTP ${self.status_code}): ${self.response_body}"
    }
  }
}

locals {
  kubex_jwt = sensitive(jsondecode(data.http.authorize.response_body).apiToken)

  graphql_url = "${var.kubex_api_base_url}/api/graphql/cloudex/connections"

  graphql_headers = {
    "Content-Type"  = "application/json"
    "Authorization" = "Bearer ${local.kubex_jwt}"
  }

  oci_settings = {
    tenancyOCID = var.tenancy_ocid
    userOCID    = local.user_ocid
    region      = var.region
    fingerPrint = oci_identity_domains_api_key.kubex.fingerprint
    sshKey      = tls_private_key.kubex.private_key_pem
  }
}

resource "time_sleep" "api_key_propagation" {
  depends_on      = [oci_identity_domains_api_key.kubex]
  create_duration = "60s"
}

data "http" "verify_connection" {
  url    = local.graphql_url
  method = "POST"

  request_headers = local.graphql_headers

  request_body = jsonencode({
    operationName = "OracleCloudexConnectionsList"
    variables = {
      ociSettings = local.oci_settings
    }
    query = <<-EOT
      query OracleCloudexConnectionsList($ociSettings: ociConnectionSettings) {
        verifyConnectionSettings(ociSettings: $ociSettings) {
          platform
          status
          statusDetails
          ociData
          accountName
          __typename
        }
      }
    EOT
  })

  depends_on = [time_sleep.api_key_propagation]

  lifecycle {
    postcondition {
      condition = (
        self.status_code == 200
        && !can(jsondecode(self.response_body).errors)
        && try(jsondecode(self.response_body).data.verifyConnectionSettings, null) != null
      )
      error_message = "Kubex verify failed (HTTP ${self.status_code}): ${self.response_body}"
    }
  }
}

data "http" "list_connections" {
  url    = local.graphql_url
  method = "POST"

  request_headers = local.graphql_headers

  request_body = jsonencode({
    operationName = "GetConnections"
    variables     = {}
    query = <<-EOT
      query GetConnections($platform: PLATFORM) {
        connectionList(platform: $platform) {
          maxRefreshAge
          connections {
            cloudPlatform
            connectionName
            lastSuccessfulVerificationDate
            createdBy
            createdOn
            updatedBy
            updatedOn
            lastestAuditServiceCount
            subConnectionCount
            lastestAuditDate
            earliestAuditDate
            accountId
            __typename
          }
          __typename
        }
      }
    EOT
  })

  lifecycle {
    postcondition {
      condition = (
        self.status_code == 200
        && !can(jsondecode(self.response_body).errors)
      )
      error_message = "Kubex list connections failed (HTTP ${self.status_code}): ${self.response_body}"
    }
  }
}

locals {
  all_connections = jsondecode(data.http.list_connections.response_body).data.connectionList.connections

  matching_connections = [
    for c in local.all_connections : c
    if c.cloudPlatform == "OCI" && c.connectionName == local.effective_connection_name
  ]

  existing_connection = length(local.matching_connections) > 0 ? local.matching_connections[0] : null
  connection_exists   = local.existing_connection != null
  existing_account_id = local.connection_exists ? local.existing_connection.accountId : null
}

data "http" "save_connection" {
  count = local.connection_exists ? 0 : 1

  url    = local.graphql_url
  method = "POST"

  request_headers = local.graphql_headers

  request_body = jsonencode({
    operationName = "SaveOCIConnection"
    variables = {
      ociSettings    = local.oci_settings
      connectionName = local.effective_connection_name
    }
    query = <<-EOT
      mutation SaveOCIConnection($ociSettings: ociConnectionSettings!, $connectionName: String!) {
        saveOciConnection(ociSettings: $ociSettings, connectionName: $connectionName) {
          status
          connectionName
          auditSetId
          connectionId
          lastSuccessfulVerificationDate
          createdOn
          createdBy
          __typename
        }
      }
    EOT
  })

  depends_on = [data.http.verify_connection]

  lifecycle {
    postcondition {
      condition = (
        self.status_code == 200
        && !can(jsondecode(self.response_body).errors)
        && try(jsondecode(self.response_body).data.saveOciConnection.connectionId, null) != null
      )
      error_message = "Kubex save failed (HTTP ${self.status_code}): ${self.response_body}"
    }
  }
}

data "http" "update_connection" {
  count = local.connection_exists ? 1 : 0

  url    = local.graphql_url
  method = "POST"

  request_headers = local.graphql_headers

  request_body = jsonencode({
    operationName = "OracleConnectionUpdate"
    variables = {
      ociSettings = local.oci_settings
      accountId   = local.existing_account_id
    }
    query = <<-EOT
      mutation OracleConnectionUpdate($ociSettings: ociConnectionSettings!, $accountId: String!) {
        updateOciConnection(ociSettings: $ociSettings, accountId: $accountId) {
          status
          connectionName
          auditSetId
          connectionId
          lastSuccessfulVerificationDate
          createdOn
          createdBy
          __typename
        }
      }
    EOT
  })

  depends_on = [data.http.verify_connection]

  lifecycle {
    postcondition {
      condition = (
        self.status_code == 200
        && !can(jsondecode(self.response_body).errors)
        && try(jsondecode(self.response_body).data.updateOciConnection.connectionId, null) != null
      )
      error_message = "Kubex update failed (HTTP ${self.status_code}): ${self.response_body}"
    }
  }
}

locals {
  verify_response = jsondecode(data.http.verify_connection.response_body).data.verifyConnectionSettings

  final_connection = local.connection_exists ? (
    jsondecode(data.http.update_connection[0].response_body).data.updateOciConnection
    ) : (
    jsondecode(data.http.save_connection[0].response_body).data.saveOciConnection
  )
}
