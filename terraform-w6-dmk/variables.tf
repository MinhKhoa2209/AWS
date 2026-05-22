variable "aws_region" {
  description = "Primary workload region."
  type        = string
  default     = "us-west-2"
}

variable "project" {
  description = "Project tag."
  type        = string
  default     = "xops"
}

variable "environment" {
  description = "Environment tag."
  type        = string
  default     = "w6-dmk"
}

variable "owner" {
  description = "Owner tag."
  type        = string
  default     = "dmk"
}

variable "vpc_cidr" {
  description = "Dedicated CIDR for the standalone W6 stack."
  type        = string
  default     = "10.60.0.0/16"
}

variable "azs" {
  description = "Two AZs for multi-AZ layout."
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

variable "backend_container_port" {
  description = "Backend container port."
  type        = number
  default     = 4004
}

variable "backend_cpu" {
  description = "Fargate task CPU."
  type        = number
  default     = 512
}

variable "backend_memory" {
  description = "Fargate task memory."
  type        = number
  default     = 1024
}

variable "backend_desired_count" {
  description = "Desired ECS service count."
  type        = number
  default     = 1
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

variable "documentdb_instance_class" {
  description = "DocumentDB instance class."
  type        = string
  default     = "db.t3.medium"
}

variable "documentdb_instance_count" {
  description = "Number of DocumentDB instances."
  type        = number
  default     = 2
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

variable "create_cloudfront_distribution" {
  description = "Create CloudFront with OAC, WAF, and VPC Origin. Disable only if workshop quotas block CloudFront."
  type        = bool
  default     = true
}
