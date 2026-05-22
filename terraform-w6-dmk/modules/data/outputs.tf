output "app_runtime_secret_arn" {
  value = aws_secretsmanager_secret.app_runtime.arn
}

output "mongodb_atlas_secret_arn" {
  value = try(aws_secretsmanager_secret.mongodb_atlas[0].arn, null)
}

output "documentdb_endpoint" {
  value = aws_docdb_cluster.main.endpoint
}

output "documentdb_reader_endpoint" {
  value = aws_docdb_cluster.main.reader_endpoint
}

output "documentdb_master_secret_arn" {
  value = aws_docdb_cluster.main.master_user_secret[0].secret_arn
}

output "documentdb_cluster_arn" {
  value = aws_docdb_cluster.main.arn
}

output "efs_id" {
  value = aws_efs_file_system.shared.id
}

output "efs_arn" {
  value = aws_efs_file_system.shared.arn
}

output "media_bucket" {
  value = aws_s3_bucket.media.id
}

output "media_bucket_arn" {
  value = aws_s3_bucket.media.arn
}

output "knowledge_base_source_bucket" {
  value = aws_s3_bucket.knowledge_base_source.id
}

output "knowledge_base_source_bucket_arn" {
  value = aws_s3_bucket.knowledge_base_source.arn
}

output "logs_bucket" {
  value = aws_s3_bucket.logs.id
}

output "logs_bucket_arn" {
  value = aws_s3_bucket.logs.arn
}

output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.main.id
}

output "cognito_user_pool_client_id" {
  value = aws_cognito_user_pool_client.web.id
}
