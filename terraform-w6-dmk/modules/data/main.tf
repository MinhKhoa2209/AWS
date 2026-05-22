terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

resource "aws_secretsmanager_secret" "app_runtime" {
  name        = "xops/w6-dmk/app-runtime"
  description = "Runtime-only application secrets for ${var.name_prefix}. Populate values out-of-band so they never land in Terraform state."
  kms_key_id  = var.kms_key_arn
}

resource "aws_secretsmanager_secret" "mongodb_atlas" {
  count       = var.enable_dms ? 1 : 0
  name        = "xops/w6-dmk/mongodb-atlas-source"
  description = "MongoDB Atlas source credentials for DMS. Populate values out-of-band so they never land in Terraform state."
  kms_key_id  = var.kms_key_arn
}

resource "aws_cognito_user_pool" "main" {
  name = "${var.name_prefix}-users"

  auto_verified_attributes = ["email"]
  username_attributes      = ["email"]
  mfa_configuration        = "OFF"

  password_policy {
    minimum_length                   = 12
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  schema {
    attribute_data_type = "String"
    mutable             = true
    name                = "email"
    required            = true
  }

  schema {
    attribute_data_type = "String"
    mutable             = true
    name                = "name"
    required            = false
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }
}

resource "aws_cognito_user_pool_client" "web" {
  name         = "${var.name_prefix}-web-client"
  user_pool_id = aws_cognito_user_pool.main.id

  generate_secret                      = false
  prevent_user_existence_errors        = "ENABLED"
  explicit_auth_flows                  = ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_SRP_AUTH"]
  supported_identity_providers         = ["COGNITO"]
  allowed_oauth_flows_user_pool_client = false

  read_attributes  = ["email", "email_verified", "name"]
  write_attributes = ["email", "name"]

  access_token_validity  = 1
  id_token_validity      = 1
  refresh_token_validity = 30

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }
}

resource "aws_docdb_subnet_group" "main" {
  name       = "${var.name_prefix}-docdb-subnet-group"
  subnet_ids = var.private_data_subnet_ids

  tags = {
    Name = "${var.name_prefix}-docdb-subnet-group"
  }
}

resource "aws_docdb_cluster_parameter_group" "main" {
  family = "docdb5.0"
  name   = "${var.name_prefix}-docdb-params"

  parameter {
    name  = "tls"
    value = "enabled"
  }
}

resource "aws_docdb_cluster" "main" {
  cluster_identifier              = "${var.name_prefix}-docdb"
  engine                          = "docdb"
  engine_version                  = "5.0.0"
  master_username                 = var.documentdb_master_username
  manage_master_user_password     = true
  db_subnet_group_name            = aws_docdb_subnet_group.main.name
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.main.name
  vpc_security_group_ids          = [var.docdb_security_group_id]
  storage_encrypted               = true
  kms_key_id                      = var.kms_key_arn
  backup_retention_period         = 7
  preferred_backup_window         = "17:00-18:00"
  skip_final_snapshot             = true
  deletion_protection             = false
  enabled_cloudwatch_logs_exports = ["audit"]

  tags = {
    Name = "${var.name_prefix}-docdb"
  }
}

resource "aws_docdb_cluster_instance" "main" {
  count              = var.documentdb_instance_count
  identifier         = "${var.name_prefix}-docdb-${count.index + 1}"
  cluster_identifier = aws_docdb_cluster.main.id
  instance_class     = var.documentdb_instance_class
  engine             = "docdb"

  tags = {
    Name = "${var.name_prefix}-docdb-${count.index + 1}"
  }
}

resource "aws_efs_file_system" "shared" {
  creation_token = "${var.name_prefix}-shared"
  encrypted      = true
  kms_key_id     = var.kms_key_arn

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name = "${var.name_prefix}-shared-efs"
  }
}

resource "aws_s3_bucket" "media" {
  bucket = "${var.name_prefix}-media-${var.account_id}"
}

resource "aws_s3_bucket_public_access_block" "media" {
  bucket                  = aws_s3_bucket.media.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "media" {
  bucket = aws_s3_bucket.media.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "media" {
  bucket = aws_s3_bucket.media.id

  rule {
    id     = "transition-media-to-standard-ia"
    status = "Enabled"

    filter {}

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}

resource "aws_s3_bucket" "knowledge_base_source" {
  bucket = "${var.name_prefix}-kb-source-${var.account_id}"
}

resource "aws_s3_bucket_public_access_block" "knowledge_base_source" {
  bucket                  = aws_s3_bucket.knowledge_base_source.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "knowledge_base_source" {
  bucket = aws_s3_bucket.knowledge_base_source.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "knowledge_base_source" {
  bucket = aws_s3_bucket.knowledge_base_source.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "knowledge_base_source" {
  bucket = aws_s3_bucket.knowledge_base_source.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "knowledge_base_source" {
  bucket = aws_s3_bucket.knowledge_base_source.id

  rule {
    id     = "transition-kb-source-to-standard-ia"
    status = "Enabled"

    filter {}

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}

resource "aws_s3_bucket" "logs" {
  bucket = "${var.name_prefix}-logs-${var.account_id}"
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_efs_mount_target" "shared" {
  count           = length(var.private_app_subnet_ids)
  file_system_id  = aws_efs_file_system.shared.id
  subnet_id       = var.private_app_subnet_ids[count.index]
  security_groups = [var.efs_security_group_id]
}
