variable "tenancy_ocid" {
  description = "OCID of the OCI tenancy where Kubex resources will be created."
  type        = string
}

variable "region" {
  description = "OCI region, e.g. \"us-ashburn-1\"."
  type        = string
}

variable "domain_name" {
  description = "Display name of the Identity Domain to provision into."
  type        = string
  default     = "Default"
}

variable "user_email" {
  description = "Contact email for the service user."
  type        = string
  default     = "support@kubex.ai"
}

variable "service_user_name" {
  description = "OCI user_name for the service account."
  type        = string
  default     = "kubex-data-collector-tf"
}

variable "service_user_display_name" {
  description = "Display name (SCIM family name) for the service account."
  type        = string
  default     = "Kubex Data Collector (Terraform)"
}

variable "group_name" {
  description = "Display name of the OCI group that grants data-collection permissions."
  type        = string
  default     = "kubex-tf"
}

variable "policy_name" {
  description = "Name of the IAM policy that grants the group its permissions."
  type        = string
  default     = "kubex-data-collection-policy-tf"
}

variable "kubex_api_base_url" {
  description = "Base URL of your Kubex tenant (no trailing slash). Example: \"https://customer.kubex.ai\"."
  type        = string
}

variable "kubex_username" {
  description = "Kubex login username (typically an email). Used to obtain a bearer token via POST /api/v2/authorize."
  type        = string
}

variable "kubex_password" {
  description = "Kubex login password. Persisted to Terraform state — use an encrypted remote backend in production."
  type        = string
  sensitive   = true
}

variable "connection_name" {
  description = "Display name for the connection in Kubex. Leave empty to auto-generate as \"<tenancy-name>-terraform\"."
  type        = string
  default     = ""
}
