# W5 Evidence Pack

## Cover
- Group ID:
- Members:
- Repository:
- Previous week evidence pack:

## Terraform Evidence Pack

### Terraform scope
- Terraform stack: `terraform-w5-dmk`
- AWS account: `910012064913`
- Region: `us-west-2`
- Deployment model: standalone W5 stack
- Naming/tagging scope: `xops-w5-dmk`
- State model: local Terraform state in `terraform-w5-dmk`
- Secret files not committed: `terraform.tfvars`, `aws-workshop.ps1`, `.tfstate`, `.tfplan`
- Constraint: stack does not import or update existing `XOPS-*` or `foodiedash-*` resources.

### Terraform validation evidence
Required screenshots:
- PowerShell output of `aws sts get-caller-identity` showing account `910012064913` and role `WSParticipantRole/Participant`.
- PowerShell output of `terraform init`.
- PowerShell output of `terraform fmt -recursive`.
- PowerShell output of `terraform validate`.
- PowerShell output of `terraform plan` after apply showing no unexpected destroy/replace.
- PowerShell output of `terraform output`.

Commands:

```powershell
cd D:\AWS\Deploy\terraform-w5-dmk
.\aws-workshop.ps1
aws sts get-caller-identity
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform output
```

### Terraform outputs

```text
account_id = "910012064913"
aws_region = "us-west-2"
vpc_id = "vpc-09bb0ead5879f6c36"
nat_eips_for_atlas_allowlist = ["52.42.233.39", "44.254.8.163"]
frontend_bucket = "xops-w5-dmk-fe-910012064913"
cloudfront_domain_name = "d3t1geq8n6hvhj.cloudfront.net"
cloudfront_distribution_id = "E217X7CHTN1SCP"
waf_web_acl_arn = "arn:aws:wafv2:us-east-1:910012064913:global/webacl/xops-w5-dmk-cloudfront-waf/86aace07-5c02-46b1-b632-c487454adc13"
private_alb_dns_name = "internal-xops-w5-dmk-alb-835647493.us-west-2.elb.amazonaws.com"
ecr_repository_url = "910012064913.dkr.ecr.us-west-2.amazonaws.com/xops-w5-dmk-be"
ecs_cluster_name = "xops-w5-dmk-cluster"
ecs_service_name = "xops-w5-dmk-backend-service"
documentdb_endpoint = "xops-w5-dmk-docdb.cluster-cxssa6wm4z16.us-west-2.docdb.amazonaws.com"
efs_id = "fs-01a57288ffa10175c"
ops_runner_instance_id = "i-052ed317c1d6868f0"
rag_api_url = "https://oi3hwyrwz6.execute-api.us-west-2.amazonaws.com/prod"
rag_api_key_id = "4n3hcvb92h"
backup_vault_name = "xops-w5-dmk-backup-vault"
backup_plan_id = "576abd36-824e-4ab9-a7bd-36a13fa0e2cf"
dms_task_arn = "arn:aws:dms:us-west-2:910012064913:task:67TQ2LYIHRCNNN2NBNKMAOKI5E"
```

### Terraform-managed resource groups
- Network: VPC, public/firewall/private app/private data subnets, route tables, NAT gateways, VPC Flow Logs, Network Firewall.
- Frontend: S3 private bucket, S3 OAC bucket policy, CloudFront distribution, CloudFront VPC Origin, WAF Web ACL.
- Backend: ECR repository, private ALB, target group, ECS cluster, ECS task definition, ECS service, ECS CloudWatch log group.
- Security/IAM: KMS key, security groups, ECS/Lambda/Backup/DMS/ops-runner roles and policies.
- Data: DocumentDB cluster, DocumentDB instance, subnet group, parameter group, Secrets Manager secrets.
- Storage/backup: EFS file system, EFS mount targets, EC2 ops-runner, AWS Backup vault, backup plan, backup selection.
- API/RAG: Lambda RAG, Lambda alias, provisioned concurrency, API Gateway REST API, API key, usage plan.
- Migration: DMS replication instance, endpoints, certificate, replication task when `enable_dms = true`.

### Terraform screenshots to include
- `terraform output` terminal screenshot showing the key IDs above.
- VPC console screenshot for `xops-w5-dmk-vpc`.
- CloudFront distribution screenshot for `E217X7CHTN1SCP`.
- ECS service screenshot for `xops-w5-dmk-backend-service`.
- DocumentDB cluster screenshot for `xops-w5-dmk-docdb`.
- EFS screenshot for `fs-01a57288ffa10175c`.
- AWS Backup vault screenshot for `xops-w5-dmk-backup-vault`.
- API Gateway screenshot for RAG REST API and API key/usage plan.
- DMS task screenshot for task ARN ending `67TQ2LYIHRCNNN2NBNKMAOKI5E`.

### Terraform acceptance
- All W5 resources are created under the `xops-w5-dmk` stack scope.
- `terraform plan` does not show accidental destroy/replace for shared resources.
- `terraform output` provides the resource identifiers used in MH1-MH5 evidence.
- Secrets are kept out of git and referenced through local `terraform.tfvars` plus AWS Secrets Manager.

## MH1 - VPC Flow Logs
- Flow Logs log group: `/aws/vpc/xops-w5-dmk/flow-logs`
- Sample `ACCEPT` log:
- Sample `REJECT` log:

## MH2 - Network Firewall
- Firewall ARN: `arn:aws:network-firewall:us-west-2:910012064913:firewall/XOPS-network-firewall`
- Alert log group:
- Blocked request evidence:
- Allowed NAT egress evidence:

## MH3 - EFS, EBS, DocumentDB Backup
- EFS ID: `fs-070e3f1ecce4bacd8`
- EFS mount targets: `fsmt-0b26a27c5b1331b99`, `fsmt-09a6b88c03193f762`
- EC2 ops-runner ID: `i-044c9afc93ea1ea03`
- EC2 ops-runner state: `running`
- EC2 ops-runner EFS mount user-data: cloud-init finished successfully after adding dependency on EFS mount targets
- Backup vault: `xops-workshop-backup-vault`
- Backup plan ID: `ac7b6b92-7dbc-4838-a4b6-303ba4dfdb86`
- Backup selection ID: `4fcda417-ef9d-4321-838e-fce04f28a5af`
- Backup job completed: `b5091cee-b78d-48ad-b224-95fc5e74a47d`, state `COMPLETED`, percent `100.0`
- Restore test result:

## MH4 - API Gateway Key
- Current XOPS API is API Gateway v2 HTTP API `awi3rax00b`; HTTP APIs do not support REST API keys/usage plans.
- Request with `x-api-key` returns `200`:
- Request without key returns `403`:

## MH5 - Lambda Provisioned Concurrency
- Lambda function:
- Alias/version:
- Metric before:
- Metric after:

## Carry-forward
- CloudFront frontend URL:
- ALB backend DNS:
- XOPS HTTP API endpoint: `https://awi3rax00b.execute-api.us-west-2.amazonaws.com`
- Chat/RAG end-to-end result:
