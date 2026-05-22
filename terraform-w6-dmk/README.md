# xops-w6-dmk Terraform Stack

Standalone W6 stack. It does not import or update the existing `XOPS-*` or `foodiedash-*` resources.

## Structure

- Root module: providers, shared variables/locals, environment-specific wiring, outputs, and `moved` blocks for safe refactors.
- `modules/foundation`: KMS, VPC, subnets, routing, security groups, VPC endpoints, and Network Firewall.
- `modules/data`: Cognito, Secrets Manager, DocumentDB, EFS, and application S3 buckets.
- `modules/app`: IAM roles, ECS backend, API Gateway, Lambda functions, backup, DMS, S3 notifications, and ops-runner EC2.
- `modules/frontend`: frontend S3 bucket, CloudFront, OAC, and WAF.

If you already deployed the older flat root-module layout, keep `moved.tf` so Terraform migrates state addresses into the new module paths instead of planning replacements.

## First run

```powershell
cd D:\AWS\Deploy\terraform-w6-dmk
Copy-Item terraform.tfvars.example terraform.tfvars
.\aws-workshop.ps1
terraform init
terraform fmt -recursive
terraform validate
terraform plan
```

Review the plan carefully. It should only create resources named or tagged `xops-w6-dmk`.

`aws-workshop.ps1` and `terraform.tfvars` are intentionally ignored by git because they contain temporary workshop credentials. Real application secrets should be written directly to AWS Secrets Manager outside Terraform so they never land in `tfvars`, plans, or state.

## Deployment order

1. Apply base stack with `enable_dms = false`.
2. Push backend image to the new ECR repo from `terraform output ecr_repository_url`.
3. Upload frontend build to the private S3 bucket from `terraform output frontend_bucket`.
4. Populate the runtime application secret in Secrets Manager using `terraform output app_runtime_secret_arn`.
5. Allowlist `terraform output nat_eips_for_atlas_allowlist` in MongoDB Atlas.
6. If you need DMS, populate the MongoDB Atlas source secret in Secrets Manager, switch `enable_dms = true`, then apply again.

## Secret population

After the first apply, write real values directly to the `app-runtime` secret. Example payload:

```json
{
  "AUTH_JWT_SECRET": "CHANGE_ME",
  "AUTH_JWT_REFRESH_SECRET": "CHANGE_ME",
  "GOOGLE_APP_USER": "CHANGE_ME",
  "GOOGLE_APP_PASSWORD": "CHANGE_ME",
  "CLOUDINARY_CLOUD_NAME": "CHANGE_ME",
  "CLOUDINARY_API_KEY": "CHANGE_ME",
  "CLOUDINARY_API_SECRET": "CHANGE_ME",
  "GEMINI_API_KEY": "CHANGE_ME",
  "GROQ_API_KEY": "CHANGE_ME",
  "PAYOS_CLIENT_ID": "CHANGE_ME",
  "PAYOS_API_KEY": "CHANGE_ME",
  "PAYOS_CHECKSUM_KEY": "CHANGE_ME"
}
```

Rotate every previously exposed secret before using this stack again. The old W5 values were present in local `terraform.tfvars` and `terraform.tfstate`, so they must be treated as compromised.

## Cognito auth

This stack now provisions a Cognito user pool and app client, and the backend is wired for Cognito-first auth:

- Email/password register, login, refresh, verify-email, forgot-password, reset-password, and change-password use Cognito.
- Existing Mongo users are migrated on first successful legacy login or password-reset flow.
- Legacy custom JWT secrets remain only as a temporary fallback for old sessions and the current Google OAuth path.

## Security notes

- S3 Block Public Access is enabled.
- CloudFront uses OAC for S3 access.
- CloudFront uses WAF in `us-east-1`.
- CloudFront sends backend paths to HTTP API; HTTP API uses VPC Link to the private ALB.
- ECS task definition passes only non-secret config plus secret ARNs; the backend fetches real secret values at runtime from Secrets Manager.
- Rotate `AUTH_JWT_SECRET` and `AUTH_JWT_REFRESH_SECRET` again after the final legacy JWT fallback is removed.
