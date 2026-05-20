# Single Tenancy Onboarding Example

Onboards one OCI tenancy to Kubex.

## Run it

From OCI Cloud Shell (signed in as a tenancy admin):

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform apply
```

Or pass variables inline:

```bash
terraform init
terraform apply \
  -var="tenancy_ocid=ocid1.tenancy.oc1..xxx" \
  -var="region=us-ashburn-1" \
  -var="kubex_api_base_url=https://<your-instance>.kubex.ai" \
  -var="kubex_username=you@example.com" \
  -var="kubex_password=$KUBEX_PASSWORD"
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