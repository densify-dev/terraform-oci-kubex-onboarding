# Kubex Onboarding for OCI

This module onboards an OCI tenancy to Kubex in one `terraform apply`. The apply does the following:

1. Provisions a service user, group, policy, and API key in the specified Tenancy and Identity Domain
2. Validates the API key using Kubex API
3. Saves the connection in Kubex

The OCI service user has no console password and cannot sign in
interactively. Its only credential is the API key uploaded by this module.

The private key, fingerprint, and other credentials are never output. They're
generated inside Terraform and pushed directly to Kubex via API.

## Prerequisites

- OCI tenancy administrator access
- Terraform 1.5+ (pre-installed in OCI Cloud Shell)
- Kubex username and password

## Quickstart

This module is meant to be invoked from a small root configuration that supplies the OCI provider. Below is a simple root configuration.

```hcl
terraform {
  required_providers {
    oci = { source = "oracle/oci", version = "~> 5.0" }
  }
}

provider "oci" {
  tenancy_ocid = var.tenancy_ocid
  region       = var.region
}

module "kubex" {
  source = "git::https://github.com/densify-dev/terraform-oci-kubex-onboarding.git?ref=v0.1.0"   # or local path

  tenancy_ocid       = var.tenancy_ocid
  region             = var.region
  kubex_api_base_url = var.kubex_api_base_url
  kubex_username     = var.kubex_username
  kubex_password     = var.kubex_password
}

variable "tenancy_ocid"           { type = string }
variable "region"                 { type = string }
variable "kubex_api_base_url"     { type = string }
variable "kubex_username"         { type = string }
variable "kubex_password" { 
    type = string 
    sensitive = true 
}
```
Paste the above snippet into your main.tf and create a terraform.tfvars with the following required values:

```
tenancy_ocid       = "ocid1.tenancy.oc1..xxxxxxxxxxx"
region             = "us-ashburn-1"
kubex_api_base_url = "https://<your-instance>.kubex.ai"
kubex_username     = "user@example.com"
kubex_password     = "your-kubex-password"
```

Then run init, plan and apply:

```
terraform init
terraform plan
terraform apply
```

A successful apply ends with:

```
Outputs:
kubex_action          = "create"
kubex_connection_id   = "2905dad4-2fcf-45f1-9a26-4db4ffb15c55"
kubex_connection_name = "tenancyname-tf"
kubex_verify_status = {
  account_name   = "..."
  platform       = "OCI"
  status         = "true"
  status_details = "..."
}
user_ocid = "ocid1.user.oc1..aaaabbbccc"
```

See [`examples/single-tenancy/`](examples/single-tenancy/) for more details.

## Inputs

| Name                        | Required | Default                          | Description                                                       |
| --------------------------- | -------- | -------------------------------- | ----------------------------------------------------------------- |
| `tenancy_ocid`              | yes      | —                                | OCI tenancy OCID                                                  |
| `region`                    | yes      | —                                | OCI region, e.g. `us-ashburn-1`                                   |
| `kubex_api_base_url`        | yes      | —                                | Base URL of your Kubex tenant, no trailing slash                  |
| `kubex_username`            | yes      | —                                | Kubex login (email)                                               |
| `kubex_password`            | yes      | —                                | Kubex password (sensitive)                                        
| `domain_name`               | no       | `Default`                        | Identity Domain to provision into                                 |
| `service_user_name`         | no       | `kubex-data-collector-tf`           | OCI `user_name` for the service account                           |
| `service_user_display_name` | no       | `Kubex Data Collector (Terraform)`           | Display name for the service account                |
| `group_name`                | no       | `kubex-tf`                          | Group name; referenced in policy statements                       |
| `policy_name`               | no       | `kubex-data-collection-policy-tf`   | IAM policy name                                                   |
| `user_email`                | no       | `support@kubex.ai`               | Contact email on the service user                                 |

## Offboarding

To remove the service user, group, policy and API keys for offboarding, run `terraform destroy`.