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
  default     = "w5-dmk"
}

variable "owner" {
  description = "Owner tag."
  type        = string
  default     = "dmk"
}

variable "vpc_cidr" {
  description = "Dedicated CIDR for the standalone W5 stack."
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

variable "app_secret_values" {
  description = "Non-derived application secrets stored as JSON in Secrets Manager. Do not commit real values."
  type = object({
    auth_jwt_secret         = string
    auth_jwt_refresh_secret = string
    google_app_user         = string
    google_app_password     = string
    google_client_id        = string
    cloudinary_cloud_name   = string
    cloudinary_api_key      = string
    cloudinary_api_secret   = string
    gemini_api_key          = string
    groq_api_key            = string
    payos_client_id         = string
    payos_api_key           = string
    payos_checksum_key      = string
    ai_microservice_url     = string
    app_origin              = string
  })
  sensitive = true
}

variable "documentdb_master_username" {
  description = "DocumentDB master username."
  type        = string
  default     = "xopsadmin"
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
}

variable "enable_dms" {
  description = "Create DMS endpoints/task for MongoDB Atlas to DocumentDB migration."
  type        = bool
  default     = false
}

variable "mongodb_atlas" {
  description = "MongoDB Atlas source connection details for DMS. Required when enable_dms=true."
  type = object({
    server_name = string
    port        = number
    database    = string
    username    = string
    password    = string
    auth_source = string
  })
  sensitive = true
  default = {
    server_name = ""
    port        = 27017
    database    = ""
    username    = ""
    password    = ""
    auth_source = "admin"
  }
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
