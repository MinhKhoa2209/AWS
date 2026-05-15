resource "aws_docdb_subnet_group" "main" {
  name       = "${local.name_prefix}-docdb-subnet-group"
  subnet_ids = aws_subnet.private_data[*].id

  tags = {
    Name = "${local.name_prefix}-docdb-subnet-group"
  }
}

resource "aws_docdb_cluster_parameter_group" "main" {
  family = "docdb5.0"
  name   = "${local.name_prefix}-docdb-params"

  parameter {
    name  = "tls"
    value = "enabled"
  }
}

resource "aws_docdb_cluster" "main" {
  cluster_identifier              = "${local.name_prefix}-docdb"
  engine                          = "docdb"
  engine_version                  = "5.0.0"
  master_username                 = var.documentdb_master_username
  master_password                 = random_password.docdb_master.result
  db_subnet_group_name            = aws_docdb_subnet_group.main.name
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.main.name
  vpc_security_group_ids          = [aws_security_group.docdb.id]
  storage_encrypted               = true
  kms_key_id                      = aws_kms_key.main.arn
  backup_retention_period         = 7
  preferred_backup_window         = "17:00-18:00"
  skip_final_snapshot             = true
  deletion_protection             = false
  enabled_cloudwatch_logs_exports = ["audit"]

  tags = {
    Name = "${local.name_prefix}-docdb"
  }
}

resource "aws_docdb_cluster_instance" "main" {
  count              = var.documentdb_instance_count
  identifier         = "${local.name_prefix}-docdb-${count.index + 1}"
  cluster_identifier = aws_docdb_cluster.main.id
  instance_class     = var.documentdb_instance_class
  engine             = "docdb"

  tags = {
    Name = "${local.name_prefix}-docdb-${count.index + 1}"
  }
}
