variable "name_prefix" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "aws_region" {
  type = string
}

variable "app_origin" {
  type = string
}

variable "google_client_id" {
  type = string
}

variable "ai_microservice_url" {
  type = string
}

variable "backend_container_port" {
  type = number
}

variable "backend_cpu" {
  type = number
}

variable "backend_memory" {
  type = number
}

variable "backend_desired_count" {
  type = number
}

variable "enable_auto_shutdown" {
  type = bool
}

variable "auto_shutdown_at_utc" {
  type = string
}

variable "bedrock_model_id" {
  type = string
}

variable "documentdb_database_name" {
  type = string
}

variable "ops_runner_instance_type" {
  type = string
}

variable "enable_ops_runner" {
  type = bool
}

variable "enable_backup" {
  type = bool
}

variable "enable_dms" {
  type = bool
}

variable "mongodb_atlas_auth_source" {
  type = string
}

variable "dms_migration_type" {
  type = string
}

variable "enable_lambda_provisioned_concurrency" {
  type = bool
}

variable "kms_key_arn" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_app_subnet_ids" {
  type = list(string)
}

variable "alb_security_group_id" {
  type = string
}

variable "ecs_security_group_id" {
  type = string
}

variable "api_gateway_vpc_link_security_group_id" {
  type = string
}

variable "dms_security_group_id" {
  type = string
}

variable "ops_runner_security_group_id" {
  type = string
}

variable "efs_id" {
  type = string
}

variable "efs_arn" {
  type = string
}

variable "media_bucket" {
  type = string
}

variable "media_bucket_arn" {
  type = string
}

variable "knowledge_base_source_bucket" {
  type = string
}

variable "knowledge_base_source_bucket_arn" {
  type = string
}

variable "app_runtime_secret_arn" {
  type = string
}

variable "mongodb_atlas_secret_arn" {
  type = string
}

variable "documentdb_master_secret_arn" {
  type = string
}

variable "documentdb_cluster_arn" {
  type = string
}

variable "cognito_user_pool_id" {
  type = string
}

variable "cognito_user_pool_client_id" {
  type = string
}
