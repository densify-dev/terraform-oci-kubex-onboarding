terraform {
  required_version = ">= 1.5"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.11"
    }
  }
}

data "oci_identity_domains" "all" {
  compartment_id = var.tenancy_ocid
  display_name   = var.domain_name
}

data "oci_identity_tenancy" "current" {
  tenancy_id = var.tenancy_ocid
}

locals {
  domain_url = length(data.oci_identity_domains.all.domains) > 0 ? data.oci_identity_domains.all.domains[0].url : null

  effective_connection_name = (
    var.connection_name != ""
    ? var.connection_name
    : "${data.oci_identity_tenancy.current.name}-terraform"
  )
}

resource "terraform_data" "domain_validation" {
  lifecycle {
    precondition {
      condition = local.domain_url != null
      error_message = <<-EOT
        No Identity Domain named "${var.domain_name}" found in tenancy ${var.tenancy_ocid}.
        Verify the domain exists and that the user running Terraform has read access to it.
      EOT
    }
  }
}

data "oci_identity_domains_users" "existing" {
  idcs_endpoint = local.domain_url
  user_filter   = "userName eq \"${var.service_user_name}\""
}

data "oci_identity_domains_groups" "existing" {
  idcs_endpoint = local.domain_url
  group_filter  = "displayName eq \"${var.group_name}\""
}

data "oci_identity_policies" "existing" {
  compartment_id = var.tenancy_ocid

  filter {
    name   = "name"
    values = [var.policy_name]
  }
}

locals {
  existing_users    = data.oci_identity_domains_users.existing.users
  existing_groups   = data.oci_identity_domains_groups.existing.groups
  existing_policies = data.oci_identity_policies.existing.policies

  user_already_exists   = length(local.existing_users) > 0
  group_already_exists  = length(local.existing_groups) > 0
  policy_already_exists = length(local.existing_policies) > 0
}

resource "oci_identity_domains_user" "kubex" {
  count = local.user_already_exists ? 0 : 1

  idcs_endpoint = local.domain_url
  schemas       = ["urn:ietf:params:scim:schemas:core:2.0:User"]
  user_name     = var.service_user_name

  name {
    family_name = var.service_user_display_name
  }

  emails {
    primary = true
    type    = "work"
    value   = var.user_email
  }
}

locals {
  user_id = local.user_already_exists ? (
    local.existing_users[0].id
  ) : oci_identity_domains_user.kubex[0].id

  user_ocid = local.user_already_exists ? (
    local.existing_users[0].ocid
  ) : oci_identity_domains_user.kubex[0].ocid
}

resource "oci_identity_domains_group" "kubex" {
  count = local.group_already_exists ? 0 : 1

  idcs_endpoint = local.domain_url
  schemas       = ["urn:ietf:params:scim:schemas:core:2.0:Group"]
  display_name  = var.group_name

  members {
    type  = "User"
    value = local.user_id
  }
}

resource "oci_identity_policy" "kubex" {
  count = local.policy_already_exists ? 0 : 1

  compartment_id = var.tenancy_ocid
  name           = var.policy_name
  description    = "Policy to allow Kubex data collection"

  statements = [
    "Allow group '${var.domain_name}'/'${var.group_name}' to inspect compartments in tenancy",
    "Allow group '${var.domain_name}'/'${var.group_name}' to inspect tenancies in tenancy",
    "Allow group '${var.domain_name}'/'${var.group_name}' to read instances in tenancy",
    "Allow group '${var.domain_name}'/'${var.group_name}' to inspect instance-images in tenancy",
    "Allow group '${var.domain_name}'/'${var.group_name}' to inspect vnic-attachments in tenancy",
    "Allow group '${var.domain_name}'/'${var.group_name}' to inspect vnics in tenancy",
    "Allow group '${var.domain_name}'/'${var.group_name}' to read public-ips in tenancy",
    "Allow group '${var.domain_name}'/'${var.group_name}' to inspect instance-pools in tenancy",
    "Allow group '${var.domain_name}'/'${var.group_name}' to inspect instance-configurations in tenancy",
    "Allow group '${var.domain_name}'/'${var.group_name}' to read metrics in tenancy",
  ]

  depends_on = [oci_identity_domains_group.kubex]
}

resource "tls_private_key" "kubex" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "oci_identity_domains_api_key" "kubex" {
  idcs_endpoint = local.domain_url
  schemas       = ["urn:ietf:params:scim:schemas:oracle:idcs:apikey"]
  key           = tls_private_key.kubex.public_key_pem

  user {
    value = local.user_id
  }
}
