# ---------------------------------------------------------------------------
# Required inputs
# ---------------------------------------------------------------------------

variable "tenancy_ocid" {
  type = string
}

variable "region" {
  type    = string
  default = "us-ashburn-1"
}

variable "kubex_api_base_url" {
  type = string
}

variable "kubex_username" {
  type = string
}

variable "kubex_password" {
  type      = string
  sensitive = true
}

# ---------------------------------------------------------------------------
# OCI provider configuration
# ---------------------------------------------------------------------------

variable "oci_config_profile" {
  description = "Name of the profile section in ~/.oci/config to use for OCI auth. Leave at 'DEFAULT' if you only have one profile or are running in Cloud Shell."
  type        = string
  default     = "DEFAULT"
}

# ---------------------------------------------------------------------------
# Optional overrides — declared here so they can be set in terraform.tfvars
# without triggering "undeclared variable" warnings at the root level.
# All defaults match the module's own defaults.
# ---------------------------------------------------------------------------

variable "connection_name" {
  description = "Leave empty to auto-generate as '<tenancy-name>-terraform'. Set explicitly to override."
  type        = string
  default     = ""
}

variable "domain_name" {
  type    = string
  default = "Default"
}

variable "service_user_name" {
  type    = string
  default = "kubex-data-collector-tf"
}

variable "service_user_display_name" {
  type    = string
  default = "Kubex Data Collector (Terraform)"
}

variable "group_name" {
  type    = string
  default = "kubex-tf"
}

variable "policy_name" {
  type    = string
  default = "kubex-data-collection-policy-tf"
}

variable "user_email" {
  type    = string
  default = "support@kubex.ai"
}
