Staging environment (DEMO ONLY)

This `environments/staging` folder is provided as a demonstration of how you
might structure a staging environment in a real organization. It is NOT meant
to be applied in the same AWS account as `dev`.

DO NOT run `terraform apply` in this folder unless you have provisioned a
separate AWS account, remote state backend, and appropriate IAM roles. See
`DO_NOT_APPLY.md` for an explanation and safe alternatives.
