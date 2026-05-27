#!/usr/bin/env bash
#
# Kubex OCI onboarding — quickstart bootstrap.
#
# Drops a ready-to-run Terraform root module into ./kubex-onboarding.
# Run from OCI Cloud Shell or any machine with Terraform 1.5+ and an OCI
# session configured.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/densify-dev/terraform-oci-kubex-onboarding/v0.1.0/bootstrap.sh | bash
#
# Flags:
#   --ref <git-ref>   Module ref to pin (tag, branch, or commit). Default: v0.1.0
#   --dir <path>      Target directory. Default: ./kubex-onboarding
#   --force           Overwrite existing files in the target directory

set -euo pipefail

REPO_URL="https://github.com/densify-dev/terraform-oci-kubex-onboarding.git"
REF="v0.1.0"
TARGET_DIR="kubex-onboarding"
FORCE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ref)   REF="$2";        shift 2 ;;
    --dir)   TARGET_DIR="$2"; shift 2 ;;
    --force) FORCE=1;         shift   ;;
    -h|--help)
      sed -n '2,20p' "$0" 2>/dev/null || true
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -d "$TARGET_DIR" && $FORCE -eq 0 ]]; then
  echo "Error: directory '$TARGET_DIR' already exists. Re-run with --force to overwrite, or --dir <other-path>." >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

write_file() {
  local path="$1"
  if [[ -f "$path" && $FORCE -eq 0 ]]; then
    echo "  skip   $path (already exists)"
    return
  fi
  cat > "$path"
  echo "  write  $path"
}

echo "Bootstrapping Kubex OCI onboarding in: $(pwd)"
echo "Module ref: $REF"
echo

write_file main.tf <<EOF
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
  tenancy_ocid = var.tenancy_ocid
  region       = var.region
}

module "kubex" {
  source = "git::${REPO_URL}?ref=${REF}"

  tenancy_ocid       = var.tenancy_ocid
  region             = var.region
  kubex_api_base_url = var.kubex_api_base_url
  kubex_username     = var.kubex_username
  kubex_password     = var.kubex_password
}
EOF

write_file variables.tf <<'EOF'
variable "tenancy_ocid" {
  description = "OCID of the OCI tenancy to onboard."
  type        = string
}

variable "region" {
  description = "OCI region, e.g. \"us-ashburn-1\"."
  type        = string
}

variable "kubex_api_base_url" {
  description = "Base URL of your Kubex tenant, no trailing slash."
  type        = string
}

variable "kubex_username" {
  description = "Kubex login (email)."
  type        = string
}

variable "kubex_password" {
  description = "Kubex login password."
  type        = string
  sensitive   = true
}
EOF

write_file outputs.tf <<'EOF'
output "kubex_action" {
  description = "Whether the connection was created or updated."
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
EOF

write_file terraform.tfvars <<'EOF'
# Fill these in, then run:
#   terraform init && terraform apply

tenancy_ocid       = "ocid1.tenancy.oc1..REPLACE_ME"
region             = "us-ashburn-1"
kubex_api_base_url = "https://REPLACE_ME.kubex.ai"
kubex_username     = "you@yourcompany.com"
kubex_password     = "REPLACE_ME"
EOF

cat <<EOF

Done. Next steps:

  cd $TARGET_DIR
  \$EDITOR terraform.tfvars     # fill in the 5 values
  terraform init
  terraform apply

When apply succeeds, your tenancy is live in Kubex.
EOF
