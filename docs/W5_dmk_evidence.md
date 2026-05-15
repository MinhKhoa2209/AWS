# W5 DMK Evidence Checklist

## Terraform Guardrails
- Stack folder: `terraform-w5-dmk/`
- Stack prefix: `xops-w5-dmk`
- State is separate from `terraform/`
- `terraform validate`: passed
- Pre-apply `terraform plan`: must only create `xops-w5-dmk-*` resources
- Post-apply `terraform plan`: must show `No changes`

## Network
- VPC ID:
- CIDR: `10.60.0.0/16`
- Public subnets:
- Firewall subnets:
- Private app subnets:
- Private data subnets:
- NAT EIPs for MongoDB Atlas allowlist:
- Flow Logs log group:
- Network Firewall ARN:
- Network Firewall alert log group:

## Frontend Security
- S3 bucket:
- S3 Block Public Access: enabled
- S3 bucket policy allows only CloudFront OAC distribution ARN:
- CloudFront distribution ID:
- CloudFront domain:
- CloudFront OAC ID:
- WAF Web ACL ARN:
- Direct S3 object URL returns denied:
- CloudFront URL returns frontend:

## Backend Runtime
- ECR repo:
- ECS cluster:
- ECS service:
- Private ALB DNS:
- Target group healthy:
- ECS task has `assign_public_ip = false`:
- Task definition secrets use Secrets Manager `valueFrom`:

## DocumentDB + DMS
- DocumentDB cluster:
- DocumentDB endpoint:
- DocumentDB subnet group private:
- MongoDB Atlas source secret:
- DMS replication instance:
- DMS source endpoint:
- DMS target endpoint:
- DMS task:
- DMS task status:
- Migrated collection/count verification:

## RAG/API
- Lambda function:
- Lambda alias `live`:
- Provisioned concurrency status:
- REST API Gateway endpoint:
- API key ID:
- Request with `x-api-key` returns `200`:
- Request without key returns `403`:

## EFS + Backup
- EFS ID:
- EFS mount targets:
- Ops-runner instance:
- EFS read/write healthcheck:
- Backup vault:
- Backup plan:
- Backup selection:
- On-demand backup job ID:
- Backup job status:
