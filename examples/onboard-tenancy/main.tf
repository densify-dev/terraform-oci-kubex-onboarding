terraform {
  required_version = ">= 1.5"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
  }
}

provider "oci" {
  # Profile name from ~/.oci/config. Leave at "DEFAULT" to use the [DEFAULT]
  # section. Set to any other section name when
  # you have multiple profiles configured locally.
  config_file_profile = var.oci_config_profile

  tenancy_ocid = var.tenancy_ocid
  region       = var.region
}

module "kubex" {
  source = "../.."

  tenancy_ocid = var.tenancy_ocid
  region       = var.region

  kubex_api_base_url = var.kubex_api_base_url
  kubex_username     = var.kubex_username
  kubex_password     = var.kubex_password

  connection_name           = var.connection_name
  domain_name               = var.domain_name
  service_user_name         = var.service_user_name
  service_user_display_name = var.service_user_display_name
  group_name                = var.group_name
  policy_name               = var.policy_name
  user_email                = var.user_email
}
