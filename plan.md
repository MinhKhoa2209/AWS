# W5 Terraform Workflow cho `terraform-w5-dmk`

## Tóm tắt
- Tài liệu này mô tả workflow triển khai W5 bằng Terraform, không dùng sơ đồ kiến trúc.
- Stack chính là `terraform-w5-dmk`, một standalone Terraform stack cho tuần W5.
- Stack này không import hoặc update các resource cũ như `XOPS-*` hoặc `foodiedash-*`.
- Resource mới phải được đặt tên/tag theo ngữ cảnh `xops-w5-dmk`.
- Terraform state hiện dùng local state trong thư mục `terraform-w5-dmk`.
- `terraform.tfvars` và `aws-workshop.ps1` không được commit vì chứa secrets và temporary workshop credentials.

## Stack Terraform đang quản lý

### Network
- VPC riêng cho W5 với CIDR mặc định `10.60.0.0/16`.
- Hai AZ mặc định: `us-west-2a`, `us-west-2b`.
- Public subnets, firewall subnets, private app subnets, private data subnets.
- Internet Gateway, NAT Gateway, Elastic IP cho NAT.
- Route tables và route table associations cho từng subnet group.
- VPC Flow Logs gửi về CloudWatch Logs.
- AWS Network Firewall cho kiểm soát outbound path.

### Frontend
- S3 private bucket cho frontend build.
- S3 Block Public Access.
- CloudFront Origin Access Control cho S3 origin.
- CloudFront VPC Origin trỏ về private ALB.
- CloudFront distribution cho frontend và backend routes.
- WAF Web ACL cho CloudFront.
- Response headers policy cho security headers.

### Backend
- ECR repository cho backend image.
- Private Application Load Balancer.
- ECS cluster, ECS task definition, ECS service chạy backend container.
- CloudWatch Log Group cho ECS logs.
- Secrets Manager lưu application secrets và runtime config.
- IAM roles/policies cho ECS task execution và application task.

### Data và migration
- Amazon DocumentDB subnet group, parameter group, cluster, cluster instances.
- Secrets Manager lưu DocumentDB credentials.
- DMS chỉ được tạo khi `enable_dms = true`.
- DMS dùng MongoDB Atlas làm source và DocumentDB làm target.
- NAT EIP từ Terraform output phải được allowlist trong MongoDB Atlas trước khi bật DMS.

### W5 evidence services
- KMS key dùng cho encryption.
- EFS shared file system và mount targets.
- EC2 `ops-runner` trong private subnet để mount/test EFS và hỗ trợ restore test.
- AWS Backup vault, backup plan, backup selection.
- Lambda RAG, API Gateway, API key, usage plan.
- Lambda provisioned concurrency cho RAG Lambda.

## Workflow triển khai

### 1. Chuẩn bị credentials
1. Mở AWS Workshop Studio.
2. Vào `AWS account access` -> `Get AWS CLI credentials`.
3. Chọn tab `Windows (PowerShell)`.
4. Copy temporary credentials vào file local:

```powershell
cd D:\AWS\Deploy\terraform-w5-dmk
Copy-Item terraform.tfvars.example terraform.tfvars
Copy-Item aws-workshop.example.ps1 aws-workshop.ps1
```

5. Dán credentials thật vào `aws-workshop.ps1`.
6. Load credentials:

```powershell
.\aws-workshop.ps1
```

7. Xác nhận session:

```powershell
aws sts get-caller-identity
aws configure get region
```

Nếu credentials hết hạn, quay lại Workshop Studio lấy credentials mới rồi chạy lại `.\aws-workshop.ps1`.

### 2. Chuẩn bị cấu hình Terraform
1. Làm việc trong thư mục Terraform:

```powershell
cd D:\AWS\Deploy\terraform-w5-dmk
```

2. Kiểm tra `terraform.tfvars` đã có các giá trị nền:

```hcl
aws_region  = "us-west-2"
project     = "xops"
environment = "w5-dmk"
owner       = "dmk"
vpc_cidr    = "10.60.0.0/16"
```

3. Điền secrets thật vào `app_secret_values`.
4. Điền `app_origin` sau khi có CloudFront domain; trước lần apply đầu có thể để placeholder.
5. Giữ `enable_dms = false` ở lần apply đầu.
6. Chỉ điền `mongodb_atlas` thật sau khi đã có NAT EIP để allowlist trong MongoDB Atlas.

### 3. Apply base stack
1. Khởi tạo và kiểm tra Terraform:

```powershell
terraform init
terraform fmt -recursive
terraform validate
terraform plan
```

2. Đọc kỹ plan trước khi apply:
- Plan hợp lệ chỉ tạo hoặc cập nhật resource thuộc stack `xops-w5-dmk`.
- Không được import, replace, destroy, hoặc update các resource cũ `XOPS-*` hoặc `foodiedash-*`.
- Lần apply đầu phải giữ `enable_dms = false`.
- Nếu CloudFront quota hoặc workshop restriction chặn deployment, cân nhắc đặt `create_cloudfront_distribution = false` và ghi rõ trade-off trong evidence.

3. Apply base stack:

```powershell
terraform apply
```

4. Lưu các output nền:

```powershell
terraform output
terraform output ecr_repository_url
terraform output frontend_bucket
terraform output cloudfront_domain_name
terraform output nat_eips_for_atlas_allowlist
```

### 4. Deploy application
1. Lấy ECR repository URL:

```powershell
terraform output ecr_repository_url
```

2. Build backend image từ source backend và push vào ECR repository trên.
3. ECS service và task definition đã được Terraform tạo; sau khi image có trên ECR, force new deployment nếu cần để service pull image mới.
4. Build frontend từ source frontend.
5. Upload frontend build vào S3 bucket:

```powershell
terraform output frontend_bucket
```

6. Nếu CloudFront được bật, test frontend bằng:

```powershell
terraform output cloudfront_domain_name
```

7. Test backend route qua CloudFront hoặc private ALB tùy cấu hình đang dùng trong evidence.

### 5. Chuẩn bị MongoDB Atlas và DMS
1. Lấy NAT EIP để allowlist trong MongoDB Atlas:

```powershell
terraform output nat_eips_for_atlas_allowlist
```

2. Vào MongoDB Atlas, allowlist toàn bộ NAT EIP Terraform trả về.
3. Cập nhật `terraform.tfvars` với thông tin thật:

```hcl
enable_dms = true
mongodb_atlas = {
  server_name = "..."
  port        = 27017
  database    = "..."
  username    = "..."
  password    = "..."
  auth_source = "admin"
}
dms_migration_type = "full-load"
```

4. Chạy plan riêng cho thay đổi DMS:

```powershell
terraform plan
```

5. Chỉ apply nếu plan chỉ thêm DMS resources và related secrets/IAM cho `xops-w5-dmk`:

```powershell
terraform apply
```

6. Lưu DMS task ARN:

```powershell
terraform output dms_task_arn
```

### 6. Thu evidence W5
Lưu output chính:

```powershell
terraform output vpc_id
terraform output cloudfront_domain_name
terraform output cloudfront_distribution_id
terraform output waf_web_acl_arn
terraform output private_alb_dns_name
terraform output ecr_repository_url
terraform output ecs_cluster_name
terraform output ecs_service_name
terraform output documentdb_endpoint
terraform output efs_id
terraform output ops_runner_instance_id
terraform output rag_api_url
terraform output rag_api_key_id
terraform output backup_vault_name
terraform output backup_plan_id
terraform output dms_task_arn
```

Evidence cần có:
- VPC Flow Logs có sample traffic `ACCEPT` hoặc `REJECT`.
- Network Firewall có log hoặc rule test chứng minh outbound filtering.
- EFS mount được từ ECS hoặc EC2 `ops-runner`, có test read/write file thật.
- AWS Backup job hoàn tất cho resource trong backup selection.
- API Gateway request có `x-api-key` trả thành công, thiếu key bị chặn.
- Lambda RAG có provisioned concurrency và metric liên quan.
- Frontend load được qua CloudFront nếu `create_cloudfront_distribution = true`.
- Backend service healthy trong ECS và nhận request qua đường publish đã chọn.
- DocumentDB endpoint được backend dùng làm database target.
- DMS task chạy được sau khi Atlas allowlist NAT EIP, nếu `enable_dms = true`.

Cập nhật evidence vào:

```text
docs/W5_evidence.md
```
