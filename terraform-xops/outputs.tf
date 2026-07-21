output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  value = data.aws_region.current.name
}

output "vpc_id" {
  value = module.foundation.vpc_id
}

output "nat_eips_for_atlas_allowlist" {
  description = "Allowlist these NAT EIPs in MongoDB Atlas before running DMS."
  value       = module.foundation.nat_eips_for_atlas_allowlist
}

output "frontend_bucket" {
  value = module.frontend.frontend_bucket
}

output "cloudfront_domain_name" {
  value = module.frontend.cloudfront_domain_name
}

output "cloudfront_distribution_id" {
  value = module.frontend.cloudfront_distribution_id
}

output "waf_web_acl_arn" {
  value = module.frontend.waf_web_acl_arn
}

output "private_alb_dns_name" {
  value = module.app.private_alb_dns_name
}

output "http_api_endpoint" {
  value = module.app.http_api_endpoint
}

output "http_api_vpc_link_id" {
  value = module.app.http_api_vpc_link_id
}

output "ecr_repository_url" {
  value = module.app.ecr_repository_url
}

output "ecs_cluster_name" {
  value = module.app.ecs_cluster_name
}

output "ecs_service_name" {
  value = module.app.ecs_service_name
}

output "documentdb_endpoint" {
  value = module.data.documentdb_endpoint
}

output "documentdb_reader_endpoint" {
  value = module.data.documentdb_reader_endpoint
}

output "efs_id" {
  value = module.data.efs_id
}

output "ops_runner_instance_id" {
  value = module.app.ops_runner_instance_id
}

output "rag_api_url" {
  value = module.app.rag_api_url
}

output "media_bucket" {
  value = module.data.media_bucket
}

output "knowledge_base_source_bucket" {
  value = module.data.knowledge_base_source_bucket
}

output "logs_bucket" {
  value = module.data.logs_bucket
}

output "app_runtime_secret_arn" {
  value = module.data.app_runtime_secret_arn
}

output "documentdb_master_secret_arn" {
  value = module.data.documentdb_master_secret_arn
}

output "cognito_user_pool_id" {
  value = module.data.cognito_user_pool_id
}

output "cognito_user_pool_client_id" {
  value = module.data.cognito_user_pool_client_id
}

output "sync_lambda_name" {
  value = module.app.sync_lambda_name
}

output "backup_vault_name" {
  value = module.app.backup_vault_name
}

output "backup_plan_id" {
  value = module.app.backup_plan_id
}

output "dms_task_arn" {
  value = module.app.dms_task_arn
}
