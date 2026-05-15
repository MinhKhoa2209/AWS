resource "aws_backup_vault" "main" {
  name        = "${local.name_prefix}-backup-vault"
  kms_key_arn = aws_kms_key.main.arn
}

resource "aws_backup_plan" "main" {
  name = "${local.name_prefix}-backup-plan"

  rule {
    rule_name         = "daily"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 17 ? * * *)"

    lifecycle {
      delete_after = 7
    }
  }
}

resource "aws_backup_selection" "main" {
  iam_role_arn = aws_iam_role.backup.arn
  name         = "${local.name_prefix}-backup-selection"
  plan_id      = aws_backup_plan.main.id

  resources = concat(
    [aws_efs_file_system.shared.arn],
    [aws_instance.ops_runner.arn],
    [aws_docdb_cluster.main.arn]
  )
}
