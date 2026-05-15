resource "aws_dms_replication_subnet_group" "main" {
  count = var.enable_dms ? 1 : 0

  replication_subnet_group_description = "DMS subnet group for ${local.name_prefix}"
  replication_subnet_group_id          = "${local.name_prefix}-dms-subnet-group"
  subnet_ids                           = aws_subnet.private_app[*].id
}

resource "aws_dms_replication_instance" "main" {
  count = var.enable_dms ? 1 : 0

  allocated_storage           = 50
  apply_immediately           = true
  auto_minor_version_upgrade  = true
  engine_version              = "3.5.4"
  multi_az                    = false
  publicly_accessible         = false
  replication_instance_class  = "dms.t3.small"
  replication_instance_id     = "${local.name_prefix}-dms"
  replication_subnet_group_id = aws_dms_replication_subnet_group.main[0].id
  vpc_security_group_ids      = [aws_security_group.dms.id]
  kms_key_arn                 = aws_kms_key.main.arn
}

resource "aws_dms_certificate" "docdb" {
  count = var.enable_dms ? 1 : 0

  certificate_id  = "${local.name_prefix}-docdb-ca"
  certificate_pem = file("${path.module}/global-bundle.pem")
}

resource "aws_dms_endpoint" "mongodb_atlas_source" {
  count = var.enable_dms ? 1 : 0

  endpoint_id                     = "${local.name_prefix}-mongodb-atlas-source"
  endpoint_type                   = "source"
  engine_name                     = "mongodb"
  secrets_manager_access_role_arn = aws_iam_role.dms_secrets[0].arn
  secrets_manager_arn             = aws_secretsmanager_secret.mongodb_atlas[0].arn
  ssl_mode                        = "require"

  mongodb_settings {
    auth_mechanism      = "default"
    auth_source         = var.mongodb_atlas.auth_source
    auth_type           = "password"
    docs_to_investigate = "1000"
    extract_doc_id      = "true"
    nesting_level       = "none"
  }

  depends_on = [aws_iam_role_policy.dms_secrets]
}

resource "aws_dms_endpoint" "docdb_target" {
  count = var.enable_dms ? 1 : 0

  endpoint_id     = "${local.name_prefix}-docdb-target"
  endpoint_type   = "target"
  engine_name     = "docdb"
  server_name     = aws_docdb_cluster.main.endpoint
  port            = 27017
  database_name   = "xops"
  username        = var.documentdb_master_username
  password        = random_password.docdb_master.result
  certificate_arn = aws_dms_certificate.docdb[0].certificate_arn
  ssl_mode        = "verify-full"
}

resource "aws_dms_replication_task" "mongodb_to_docdb" {
  count = var.enable_dms ? 1 : 0

  migration_type           = var.dms_migration_type
  replication_instance_arn = aws_dms_replication_instance.main[0].replication_instance_arn
  replication_task_id      = "${local.name_prefix}-mongodb-to-docdb"
  source_endpoint_arn      = aws_dms_endpoint.mongodb_atlas_source[0].endpoint_arn
  target_endpoint_arn      = aws_dms_endpoint.docdb_target[0].endpoint_arn
  start_replication_task   = false

  table_mappings = jsonencode({
    rules = [
      {
        "rule-type" = "selection"
        "rule-id"   = "1"
        "rule-name" = "include-all"
        "object-locator" = {
          "schema-name" = "%"
          "table-name"  = "%"
        }
        "rule-action" = "include"
      }
    ]
  })

  replication_task_settings = jsonencode({
    TargetMetadata = {
      TargetSchema = ""
    }
    FullLoadSettings = {
      TargetTablePrepMode = "DROP_AND_CREATE"
    }
    Logging = {
      EnableLogging = true
    }
  })
}
