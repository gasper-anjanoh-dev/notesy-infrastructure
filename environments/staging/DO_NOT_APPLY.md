DO NOT APPLY

This `environments/staging` directory exists for demonstration only.

- Do NOT run `terraform apply` against this folder in your AWS account.
- This workspace is not backed by a separate AWS account; running `apply` will create real resources in the same account as `dev`.

If you want to experiment with staging, create a separate AWS account or modify CI to use a different `AWS_ROLE_ARN` or backend.
