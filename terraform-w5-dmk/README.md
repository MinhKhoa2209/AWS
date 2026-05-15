# xops-w5-dmk Terraform Stack

Standalone W5 stack. It does not import or update the existing `XOPS-*` or `foodiedash-*` resources.

## First run

```powershell
cd D:\AWS\Deploy\terraform-w5-dmk
Copy-Item terraform.tfvars.example terraform.tfvars
Copy-Item aws-workshop.example.ps1 aws-workshop.ps1
.\aws-workshop.ps1
terraform init
terraform fmt -recursive
terraform validate
terraform plan
```

Review the plan carefully. It should only create resources named or tagged `xops-w5-dmk`.

`aws-workshop.ps1` and `terraform.tfvars` are intentionally ignored by git because they contain temporary workshop credentials and secrets.

## Deployment order

1. Apply base stack with `enable_dms = false`.
2. Push backend image to the new ECR repo from `terraform output ecr_repository_url`.
3. Upload frontend build to the private S3 bucket from `terraform output frontend_bucket`.
4. Allowlist `terraform output nat_eips_for_atlas_allowlist` in MongoDB Atlas.
5. Set real Atlas values and switch `enable_dms = true`.
6. Run `terraform plan` again, then apply the DMS resources.

## Security notes

- S3 Block Public Access is enabled.
- CloudFront uses OAC for S3 access.
- CloudFront uses WAF in `us-east-1`.
- CloudFront uses VPC Origin for the private ALB.
- ECS task definition uses Secrets Manager `valueFrom` entries for runtime config.
