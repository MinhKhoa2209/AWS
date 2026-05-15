output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  value = data.aws_region.current.name
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "nat_eips_for_atlas_allowlist" {
  description = "Allowlist these NAT EIPs in MongoDB Atlas before running DMS."
  value       = aws_eip.nat[*].public_ip
}

output "frontend_bucket" {
  value = aws_s3_bucket.frontend.id
}

output "cloudfront_domain_name" {
  value = try(aws_cloudfront_distribution.main[0].domain_name, null)
}

output "cloudfront_distribution_id" {
  value = try(aws_cloudfront_distribution.main[0].id, null)
}

output "waf_web_acl_arn" {
  value = try(aws_wafv2_web_acl.cloudfront[0].arn, null)
}

output "private_alb_dns_name" {
  value = aws_lb.backend.dns_name
}

output "ecr_repository_url" {
  value = aws_ecr_repository.backend.repository_url
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  value = aws_ecs_service.backend.name
}

output "documentdb_endpoint" {
  value = aws_docdb_cluster.main.endpoint
}

output "efs_id" {
  value = aws_efs_file_system.shared.id
}

output "ops_runner_instance_id" {
  value = aws_instance.ops_runner.id
}

output "rag_api_url" {
  value = aws_api_gateway_stage.rag.invoke_url
}

output "rag_api_key_id" {
  value = aws_api_gateway_api_key.rag.id
}

output "backup_vault_name" {
  value = aws_backup_vault.main.name
}

output "backup_plan_id" {
  value = aws_backup_plan.main.id
}

output "dms_task_arn" {
  value = try(aws_dms_replication_task.mongodb_to_docdb[0].replication_task_arn, null)
}
