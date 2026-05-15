# W5 Evidence Checklist

## Terraform
- `aws sts get-caller-identity` screenshot/output: account `910012064913`, role `WSParticipantRole/Participant`
- `terraform plan` summary with no destroy/replace: `No changes. Your infrastructure matches the configuration.`
- `terraform output`: saved in `terraform/xops-post-apply-evidence-us-west-2.txt`

## MH1 - VPC Flow Logs
- Flow Logs log group: `/aws/vpc/flowlogs/XOPS`
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
