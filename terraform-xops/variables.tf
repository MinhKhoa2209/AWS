variable "aws_region" {
  description = "Primary workload region."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project tag."
  type        = string
  default     = "xops"
}

variable "environment" {
  description = "Environment tag."
  type        = string
  default     = "prod"
}

variable "owner" {
  description = "Owner tag."
  type        = string
  default     = "dmk"
}

variable "vpc_cidr" {
  description = "Dedicated CIDR for the standalone XOPS stack."
  type        = string
  default     = "10.60.0.0/16"
}

variable "azs" {
  description = "Availability zones for the stack. ALB and DocumentDB require two AZs."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]

  validation {
    condition     = length(var.azs) == 2
    error_message = "azs must contain exactly two availability zones."
  }
}

variable "nat_gateway_count" {
  description = "Number of NAT gateways. Keep 1 for lowest cost; use 2 for per-AZ resilience."
  type        = number
  default     = 1

  validation {
    condition     = var.nat_gateway_count >= 1 && var.nat_gateway_count <= length(var.azs)
    error_message = "nat_gateway_count must be between 1 and the number of AZs."
  }
}

variable "backend_container_port" {
  description = "Backend container port."
  type        = number
  default     = 4004
}

variable "backend_cpu" {
  description = "Fargate task CPU."
  type        = number
  default     = 256
}

variable "backend_memory" {
  description = "Fargate task memory."
  type        = number
  default     = 512
}

variable "backend_desired_count" {
  description = "Desired ECS service count."
  type        = number
  default     = 0
}

variable "enable_auto_shutdown" {
  description = "Create a one-time scheduler that scales the ECS backend service down to zero."
  type        = bool
  default     = false
}

variable "auto_shutdown_at_utc" {
  description = "UTC timestamp for one-time auto shutdown, using EventBridge Scheduler at() format: yyyy-mm-ddThh:mm:ss."
  type        = string
  default     = ""

  validation {
    condition     = var.auto_shutdown_at_utc == "" || can(regex("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}$", var.auto_shutdown_at_utc))
    error_message = "auto_shutdown_at_utc must be empty or formatted as yyyy-mm-ddThh:mm:ss, for example 2026-05-25T18:00:00."
  }
}

variable "app_origin" {
  description = "Allowed frontend origin for API CORS and backend runtime."
  type        = string
}

variable "google_client_id" {
  description = "Google OAuth client ID used by the backend."
  type        = string
  default     = ""
}

variable "ai_microservice_url" {
  description = "Optional internal AI microservice endpoint."
  type        = string
  default     = "http://localhost:8001"
}

variable "documentdb_master_username" {
  description = "DocumentDB master username."
  type        = string
  default     = "xopsadmin"
}

variable "documentdb_database_name" {
  description = "Logical application database name used in the MongoDB connection string."
  type        = string
  default     = "xops"
}

variable "enable_documentdb" {
  description = "Create DocumentDB. Disabled by default because AWS free plan accounts may not allow the docdb engine."
  type        = bool
  default     = false
}

variable "documentdb_instance_class" {
  description = "DocumentDB instance class."
  type        = string
  default     = "db.t3.medium"
}

variable "documentdb_instance_count" {
  description = "Number of DocumentDB instances."
  type        = number
  default     = 1

  validation {
    condition     = var.documentdb_instance_count >= 1
    error_message = "documentdb_instance_count must be at least 1."
  }
}

variable "documentdb_backup_retention_period" {
  description = "DocumentDB backup retention in days. Free plan accounts may only allow the minimum."
  type        = number
  default     = 1

  validation {
    condition     = var.documentdb_backup_retention_period >= 1 && var.documentdb_backup_retention_period <= 35
    error_message = "documentdb_backup_retention_period must be between 1 and 35."
  }
}

variable "bedrock_model_id" {
  description = "Bedrock model used by the RAG and sync Lambda functions."
  type        = string
  default     = "amazon.titan-text-express-v1"
}

variable "enable_dms" {
  description = "Create DMS endpoints/task for MongoDB Atlas to DocumentDB migration."
  type        = bool
  default     = false
}

variable "enable_network_firewall" {
  description = "Create AWS Network Firewall. Disabled by default because it has a high hourly endpoint cost."
  type        = bool
  default     = false
}

variable "enable_interface_vpc_endpoints" {
  description = "Create paid interface VPC endpoints. Disabled by default because a single NAT gateway is cheaper for low traffic."
  type        = bool
  default     = false
}

variable "enable_vpc_flow_logs" {
  description = "Create VPC Flow Logs. Disabled by default to avoid CloudWatch Logs ingestion cost."
  type        = bool
  default     = false
}

variable "enable_lambda_provisioned_concurrency" {
  description = "Keep Lambda RAG warm with provisioned concurrency. Disabled by default to avoid idle hourly cost."
  type        = bool
  default     = false
}

variable "enable_cloudfront_waf" {
  description = "Attach WAF to CloudFront. Disabled by default to avoid monthly WAF fixed costs."
  type        = bool
  default     = false
}

variable "cloudfront_price_class" {
  description = "CloudFront price class. PriceClass_100 is the lowest-cost edge footprint."
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.cloudfront_price_class)
    error_message = "cloudfront_price_class must be PriceClass_100, PriceClass_200, or PriceClass_All."
  }
}

variable "mongodb_atlas_auth_source" {
  description = "MongoDB Atlas authentication source used by DMS when the source secret is populated manually."
  type        = string
  default     = "admin"
}

variable "dms_migration_type" {
  description = "DMS migration type."
  type        = string
  default     = "full-load"

  validation {
    condition     = contains(["full-load", "cdc", "full-load-and-cdc"], var.dms_migration_type)
    error_message = "dms_migration_type must be full-load, cdc, or full-load-and-cdc."
  }
}

variable "ops_runner_instance_type" {
  description = "EC2 ops-runner instance type."
  type        = string
  default     = "t3.micro"
}

variable "enable_ops_runner" {
  description = "Create private EC2 ops-runner for manual EFS/SSM operations. Disabled by default to avoid idle EC2 cost."
  type        = bool
  default     = false
}

variable "enable_backup" {
  description = "Create AWS Backup plan/vault. Disabled by default to avoid backup storage charges."
  type        = bool
  default     = false
}

variable "create_cloudfront_distribution" {
  description = "Create CloudFront with OAC, WAF, and VPC Origin."
  type        = bool
  default     = true
}
