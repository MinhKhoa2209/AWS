locals {
  name_prefix = "${var.project}-${var.environment}"

  tags = {
    Project     = var.project
    Environment = var.environment
    Owner       = var.owner
    ManagedBy   = "terraform"
  }

  public_subnet_cidrs      = ["10.60.0.0/24", "10.60.1.0/24"]
  firewall_subnet_cidrs    = ["10.60.10.0/24", "10.60.11.0/24"]
  private_app_subnet_cidrs = ["10.60.100.0/24", "10.60.101.0/24"]
  private_data_subnet_cidrs = [
    "10.60.200.0/24",
    "10.60.201.0/24"
  ]

  app_secret_json = {
    NODE_ENV                = "production"
    PORT                    = tostring(var.backend_container_port)
    AWS_REGION              = var.aws_region
    MONGODB_URI             = "mongodb://${var.documentdb_master_username}:${random_password.docdb_master.result}@${aws_docdb_cluster.main.endpoint}:27017/xops?tls=true&replicaSet=rs0&readPreference=primary&retryWrites=false"
    RAG_API_URL             = aws_api_gateway_stage.rag.invoke_url
    RAG_LAMBDA_URL          = aws_api_gateway_stage.rag.invoke_url
    RAG_API_KEY             = aws_api_gateway_api_key.rag.value
    EFS_SHARED_PATH         = "/mnt/shared"
    APP_ORIGIN              = var.app_secret_values.app_origin
    AUTH_JWT_SECRET         = var.app_secret_values.auth_jwt_secret
    AUTH_JWT_REFRESH_SECRET = var.app_secret_values.auth_jwt_refresh_secret
    GOOGLE_APP_USER         = var.app_secret_values.google_app_user
    GOOGLE_APP_PASSWORD     = var.app_secret_values.google_app_password
    GOOGLE_CLIENT_ID        = var.app_secret_values.google_client_id
    CLOUDINARY_CLOUD_NAME   = var.app_secret_values.cloudinary_cloud_name
    CLOUDINARY_API_KEY      = var.app_secret_values.cloudinary_api_key
    CLOUDINARY_API_SECRET   = var.app_secret_values.cloudinary_api_secret
    GEMINI_API_KEY          = var.app_secret_values.gemini_api_key
    GROQ_API_KEY            = var.app_secret_values.groq_api_key
    PAYOS_CLIENT_ID         = var.app_secret_values.payos_client_id
    PAYOS_API_KEY           = var.app_secret_values.payos_api_key
    PAYOS_CHECKSUM_KEY      = var.app_secret_values.payos_checksum_key
    AI_MICROSERVICE_URL     = var.app_secret_values.ai_microservice_url
  }
}
