resource "random_password" "docdb_master" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "app" {
  name        = "xops/w5-dmk/app"
  description = "Application runtime config for ${local.name_prefix}"
  kms_key_id  = aws_kms_key.main.arn
}

resource "aws_secretsmanager_secret_version" "app" {
  secret_id     = aws_secretsmanager_secret.app.id
  secret_string = jsonencode(local.app_secret_json)
}

resource "aws_secretsmanager_secret" "docdb" {
  name        = "xops/w5-dmk/docdb"
  description = "DocumentDB credentials for ${local.name_prefix}"
  kms_key_id  = aws_kms_key.main.arn
}

resource "aws_secretsmanager_secret_version" "docdb" {
  secret_id = aws_secretsmanager_secret.docdb.id
  secret_string = jsonencode({
    username = var.documentdb_master_username
    password = random_password.docdb_master.result
    engine   = "docdb"
    host     = aws_docdb_cluster.main.endpoint
    port     = 27017
    dbname   = "xops"
  })
}

resource "aws_secretsmanager_secret" "mongodb_atlas" {
  count       = var.enable_dms ? 1 : 0
  name        = "xops/w5-dmk/mongodb-atlas-source"
  description = "MongoDB Atlas source credentials for DMS"
  kms_key_id  = aws_kms_key.main.arn
}

resource "aws_secretsmanager_secret_version" "mongodb_atlas" {
  count     = var.enable_dms ? 1 : 0
  secret_id = aws_secretsmanager_secret.mongodb_atlas[0].id
  secret_string = jsonencode({
    username   = var.mongodb_atlas.username
    password   = var.mongodb_atlas.password
    engine     = "mongodb"
    host       = var.mongodb_atlas.server_name
    port       = var.mongodb_atlas.port
    dbname     = var.mongodb_atlas.database
    authSource = var.mongodb_atlas.auth_source
  })
}

resource "aws_secretsmanager_secret" "dms_docdb_target" {
  count       = var.enable_dms ? 1 : 0
  name        = "xops/w5-dmk/dms-docdb-target"
  description = "DocumentDB target credentials for DMS"
  kms_key_id  = aws_kms_key.main.arn
}

resource "aws_secretsmanager_secret_version" "dms_docdb_target" {
  count     = var.enable_dms ? 1 : 0
  secret_id = aws_secretsmanager_secret.dms_docdb_target[0].id
  secret_string = jsonencode({
    username = var.documentdb_master_username
    password = random_password.docdb_master.result
    engine   = "docdb"
    host     = aws_docdb_cluster.main.endpoint
    port     = 27017
    dbname   = "xops"
  })
}
