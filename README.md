# Network AVM examples

A random repo to try out some examples with the network AVM module.

## Get started

Authenticate to Azure:

```bash
az login
```

Terraform usage with var file:

```bash
# if running interactively - within each example folder

# create the things
terraform plan --var-file .\environments\dev.terraform.tfvars -out tfplan
terraform apply tfplan

# remove the things
terraform plan --destroy --var-file .\environments\dev.terraform.tfvars -out tfplan
terraform apply tfplan
```
