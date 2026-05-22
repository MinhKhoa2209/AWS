output "private_alb_dns_name" {
  value = aws_lb.backend.dns_name
}

output "http_api_api_endpoint" {
  value = aws_apigatewayv2_api.main.api_endpoint
}

output "http_api_endpoint" {
  value = aws_apigatewayv2_stage.default.invoke_url
}

output "http_api_vpc_link_id" {
  value = aws_apigatewayv2_vpc_link.backend.id
}

output "ecr_repository_url" {
  value = aws_ecr_repository.backend.repository_url
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  value = aws_ecs_service.backend.name
}

output "ops_runner_instance_id" {
  value = aws_instance.ops_runner.id
}

output "rag_api_url" {
  value = "${aws_apigatewayv2_stage.default.invoke_url}rag"
}

output "sync_lambda_name" {
  value = aws_lambda_function.sync.function_name
}

output "backup_vault_name" {
  value = aws_backup_vault.main.name
}

output "backup_plan_id" {
  value = aws_backup_plan.main.id
}

output "dms_task_arn" {
  value = try(aws_dms_replication_task.mongodb_to_docdb[0].replication_task_arn, null)
}
