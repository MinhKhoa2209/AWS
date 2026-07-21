moved {
  from = aws_dms_replication_subnet_group.main
  to   = module.app.aws_dms_replication_subnet_group.main
}

moved {
  from = aws_dms_replication_instance.main
  to   = module.app.aws_dms_replication_instance.main
}

moved {
  from = aws_dms_certificate.docdb
  to   = module.app.aws_dms_certificate.docdb
}

moved {
  from = aws_dms_endpoint.mongodb_atlas_source
  to   = module.app.aws_dms_endpoint.mongodb_atlas_source
}

moved {
  from = aws_dms_endpoint.docdb_target
  to   = module.app.aws_dms_endpoint.docdb_target
}

moved {
  from = aws_dms_replication_task.mongodb_to_docdb
  to   = module.app.aws_dms_replication_task.mongodb_to_docdb
}

moved {
  from = aws_ecr_repository.backend
  to   = module.app.aws_ecr_repository.backend
}

moved {
  from = aws_cloudwatch_log_group.ecs
  to   = module.app.aws_cloudwatch_log_group.ecs
}

moved {
  from = aws_lb.backend
  to   = module.app.aws_lb.backend
}

moved {
  from = aws_lb_target_group.backend
  to   = module.app.aws_lb_target_group.backend
}

moved {
  from = aws_lb_listener.http
  to   = module.app.aws_lb_listener.http
}

moved {
  from = aws_ecs_cluster.main
  to   = module.app.aws_ecs_cluster.main
}

moved {
  from = aws_ecs_task_definition.backend
  to   = module.app.aws_ecs_task_definition.backend
}

moved {
  from = aws_ecs_service.backend
  to   = module.app.aws_ecs_service.backend
}

moved {
  from = aws_docdb_subnet_group.main
  to   = module.data.aws_docdb_subnet_group.main
}

moved {
  from = aws_docdb_cluster_parameter_group.main
  to   = module.data.aws_docdb_cluster_parameter_group.main
}

moved {
  from = aws_docdb_cluster.main
  to   = module.data.aws_docdb_cluster.main
}

moved {
  from = aws_docdb_cluster_instance.main
  to   = module.data.aws_docdb_cluster_instance.main
}

moved {
  from = aws_cognito_user_pool.main
  to   = module.data.aws_cognito_user_pool.main
}

moved {
  from = aws_cognito_user_pool_client.web
  to   = module.data.aws_cognito_user_pool_client.web
}

moved {
  from = aws_backup_vault.main
  to   = module.app.aws_backup_vault.main
}

moved {
  from = aws_backup_plan.main
  to   = module.app.aws_backup_plan.main
}

moved {
  from = aws_backup_selection.main
  to   = module.app.aws_backup_selection.main
}

moved {
  from = aws_apigatewayv2_api.main
  to   = module.app.aws_apigatewayv2_api.main
}

moved {
  from = aws_apigatewayv2_vpc_link.backend
  to   = module.app.aws_apigatewayv2_vpc_link.backend
}

moved {
  from = aws_apigatewayv2_authorizer.lambda
  to   = module.app.aws_apigatewayv2_authorizer.lambda
}

moved {
  from = aws_apigatewayv2_integration.backend
  to   = module.app.aws_apigatewayv2_integration.backend
}

moved {
  from = aws_apigatewayv2_integration.rag
  to   = module.app.aws_apigatewayv2_integration.rag
}

moved {
  from = aws_apigatewayv2_route.api_proxy
  to   = module.app.aws_apigatewayv2_route.api_proxy
}

moved {
  from = aws_apigatewayv2_route.auth_login
  to   = module.app.aws_apigatewayv2_route.auth_login
}

moved {
  from = aws_apigatewayv2_route.auth_register
  to   = module.app.aws_apigatewayv2_route.auth_register
}

moved {
  from = aws_apigatewayv2_route.auth_google
  to   = module.app.aws_apigatewayv2_route.auth_google
}

moved {
  from = aws_apigatewayv2_route.auth_refresh
  to   = module.app.aws_apigatewayv2_route.auth_refresh
}

moved {
  from = aws_apigatewayv2_route.auth_verify_email
  to   = module.app.aws_apigatewayv2_route.auth_verify_email
}

moved {
  from = aws_apigatewayv2_route.auth_resend_verify_email
  to   = module.app.aws_apigatewayv2_route.auth_resend_verify_email
}

moved {
  from = aws_apigatewayv2_route.auth_password_forgot
  to   = module.app.aws_apigatewayv2_route.auth_password_forgot
}

moved {
  from = aws_apigatewayv2_route.auth_password_verify_otp
  to   = module.app.aws_apigatewayv2_route.auth_password_verify_otp
}

moved {
  from = aws_apigatewayv2_route.auth_password_reset
  to   = module.app.aws_apigatewayv2_route.auth_password_reset
}

moved {
  from = aws_apigatewayv2_route.socket_proxy
  to   = module.app.aws_apigatewayv2_route.socket_proxy
}

moved {
  from = aws_apigatewayv2_route.rag_post
  to   = module.app.aws_apigatewayv2_route.rag_post
}

moved {
  from = aws_apigatewayv2_stage.default
  to   = module.app.aws_apigatewayv2_stage.default
}

moved {
  from = aws_lambda_permission.http_api_rag
  to   = module.app.aws_lambda_permission.http_api_rag
}

moved {
  from = aws_lambda_permission.http_api_authorizer
  to   = module.app.aws_lambda_permission.http_api_authorizer
}

moved {
  from = aws_vpc_endpoint.interface
  to   = module.foundation.aws_vpc_endpoint.interface
}

moved {
  from = aws_vpc_endpoint.s3
  to   = module.foundation.aws_vpc_endpoint.s3
}

moved {
  from = aws_s3_bucket.frontend
  to   = module.frontend.aws_s3_bucket.frontend
}

moved {
  from = aws_s3_bucket_public_access_block.frontend
  to   = module.frontend.aws_s3_bucket_public_access_block.frontend
}

moved {
  from = aws_s3_bucket_ownership_controls.frontend
  to   = module.frontend.aws_s3_bucket_ownership_controls.frontend
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.frontend
  to   = module.frontend.aws_s3_bucket_server_side_encryption_configuration.frontend
}

moved {
  from = aws_s3_bucket_versioning.frontend
  to   = module.frontend.aws_s3_bucket_versioning.frontend
}

moved {
  from = aws_cloudfront_origin_access_control.frontend
  to   = module.frontend.aws_cloudfront_origin_access_control.frontend
}

moved {
  from = aws_wafv2_web_acl.cloudfront
  to   = module.frontend.aws_wafv2_web_acl.cloudfront
}

moved {
  from = aws_cloudfront_response_headers_policy.security
  to   = module.frontend.aws_cloudfront_response_headers_policy.security
}

moved {
  from = aws_cloudfront_function.spa_rewrite
  to   = module.frontend.aws_cloudfront_function.spa_rewrite
}

moved {
  from = aws_cloudfront_distribution.main
  to   = module.frontend.aws_cloudfront_distribution.main
}

moved {
  from = aws_s3_bucket_policy.frontend_oac
  to   = module.frontend.aws_s3_bucket_policy.frontend_oac
}

moved {
  from = aws_cloudwatch_log_group.network_firewall
  to   = module.foundation.aws_cloudwatch_log_group.network_firewall
}

moved {
  from = aws_networkfirewall_rule_group.egress_domain_deny
  to   = module.foundation.aws_networkfirewall_rule_group.egress_domain_deny
}

moved {
  from = aws_networkfirewall_firewall_policy.main
  to   = module.foundation.aws_networkfirewall_firewall_policy.main
}

moved {
  from = aws_networkfirewall_firewall.main
  to   = module.foundation.aws_networkfirewall_firewall.main
}

moved {
  from = aws_route.private_app_to_firewall
  to   = module.foundation.aws_route.private_app_to_firewall
}

moved {
  from = aws_networkfirewall_logging_configuration.main
  to   = module.foundation.aws_networkfirewall_logging_configuration.main
}

moved {
  from = aws_iam_role.ecs_task_execution
  to   = module.app.aws_iam_role.ecs_task_execution
}

moved {
  from = aws_iam_role_policy_attachment.ecs_task_execution
  to   = module.app.aws_iam_role_policy_attachment.ecs_task_execution
}

moved {
  from = aws_iam_role.ecs_task
  to   = module.app.aws_iam_role.ecs_task
}

moved {
  from = aws_iam_role_policy.ecs_task_app
  to   = module.app.aws_iam_role_policy.ecs_task_app
}

moved {
  from = aws_iam_role.lambda
  to   = module.app.aws_iam_role.lambda
}

moved {
  from = aws_iam_role_policy_attachment.lambda_basic
  to   = module.app.aws_iam_role_policy_attachment.lambda_basic
}

moved {
  from = aws_iam_role_policy.lambda_bedrock
  to   = module.app.aws_iam_role_policy.lambda_bedrock
}

moved {
  from = aws_iam_role_policy.lambda_storage
  to   = module.app.aws_iam_role_policy.lambda_storage
}

moved {
  from = aws_iam_role.ops_runner
  to   = module.app.aws_iam_role.ops_runner
}

moved {
  from = aws_iam_role_policy_attachment.ops_runner_ssm
  to   = module.app.aws_iam_role_policy_attachment.ops_runner_ssm
}

moved {
  from = aws_iam_instance_profile.ops_runner
  to   = module.app.aws_iam_instance_profile.ops_runner
}

moved {
  from = aws_iam_role.backup
  to   = module.app.aws_iam_role.backup
}

moved {
  from = aws_iam_role_policy_attachment.backup
  to   = module.app.aws_iam_role_policy_attachment.backup
}

moved {
  from = aws_iam_role.dms_secrets
  to   = module.app.aws_iam_role.dms_secrets
}

moved {
  from = aws_iam_role_policy.dms_secrets
  to   = module.app.aws_iam_role_policy.dms_secrets
}

moved {
  from = aws_kms_key.main
  to   = module.foundation.aws_kms_key.main
}

moved {
  from = aws_kms_alias.main
  to   = module.foundation.aws_kms_alias.main
}

moved {
  from = aws_efs_file_system.shared
  to   = module.data.aws_efs_file_system.shared
}

moved {
  from = aws_s3_bucket.media
  to   = module.data.aws_s3_bucket.media
}

moved {
  from = aws_s3_bucket_public_access_block.media
  to   = module.data.aws_s3_bucket_public_access_block.media
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.media
  to   = module.data.aws_s3_bucket_server_side_encryption_configuration.media
}

moved {
  from = aws_s3_bucket_lifecycle_configuration.media
  to   = module.data.aws_s3_bucket_lifecycle_configuration.media
}

moved {
  from = aws_s3_bucket.knowledge_base_source
  to   = module.data.aws_s3_bucket.knowledge_base_source
}

moved {
  from = aws_s3_bucket_public_access_block.knowledge_base_source
  to   = module.data.aws_s3_bucket_public_access_block.knowledge_base_source
}

moved {
  from = aws_s3_bucket_ownership_controls.knowledge_base_source
  to   = module.data.aws_s3_bucket_ownership_controls.knowledge_base_source
}

moved {
  from = aws_s3_bucket_versioning.knowledge_base_source
  to   = module.data.aws_s3_bucket_versioning.knowledge_base_source
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.knowledge_base_source
  to   = module.data.aws_s3_bucket_server_side_encryption_configuration.knowledge_base_source
}

moved {
  from = aws_s3_bucket_lifecycle_configuration.knowledge_base_source
  to   = module.data.aws_s3_bucket_lifecycle_configuration.knowledge_base_source
}

moved {
  from = aws_s3_bucket.logs
  to   = module.data.aws_s3_bucket.logs
}

moved {
  from = aws_s3_bucket_public_access_block.logs
  to   = module.data.aws_s3_bucket_public_access_block.logs
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.logs
  to   = module.data.aws_s3_bucket_server_side_encryption_configuration.logs
}

moved {
  from = aws_lambda_permission.knowledge_base_source_sync
  to   = module.app.aws_lambda_permission.knowledge_base_source_sync
}

moved {
  from = aws_s3_bucket_notification.knowledge_base_source
  to   = module.app.aws_s3_bucket_notification.knowledge_base_source
}

moved {
  from = aws_efs_mount_target.shared
  to   = module.data.aws_efs_mount_target.shared
}

moved {
  from = aws_instance.ops_runner
  to   = module.app.aws_instance.ops_runner
}

moved {
  from = aws_vpc.main
  to   = module.foundation.aws_vpc.main
}

moved {
  from = aws_internet_gateway.main
  to   = module.foundation.aws_internet_gateway.main
}

moved {
  from = aws_subnet.public
  to   = module.foundation.aws_subnet.public
}

moved {
  from = aws_subnet.firewall
  to   = module.foundation.aws_subnet.firewall
}

moved {
  from = aws_subnet.private_app
  to   = module.foundation.aws_subnet.private_app
}

moved {
  from = aws_subnet.private_data
  to   = module.foundation.aws_subnet.private_data
}

moved {
  from = aws_eip.nat
  to   = module.foundation.aws_eip.nat
}

moved {
  from = aws_nat_gateway.main
  to   = module.foundation.aws_nat_gateway.main
}

moved {
  from = aws_route_table.public
  to   = module.foundation.aws_route_table.public
}

moved {
  from = aws_route_table_association.public
  to   = module.foundation.aws_route_table_association.public
}

moved {
  from = aws_route_table.firewall
  to   = module.foundation.aws_route_table.firewall
}

moved {
  from = aws_route_table_association.firewall
  to   = module.foundation.aws_route_table_association.firewall
}

moved {
  from = aws_route_table.private_app
  to   = module.foundation.aws_route_table.private_app
}

moved {
  from = aws_route_table_association.private_app
  to   = module.foundation.aws_route_table_association.private_app
}

moved {
  from = aws_route_table.private_data
  to   = module.foundation.aws_route_table.private_data
}

moved {
  from = aws_route_table_association.private_data
  to   = module.foundation.aws_route_table_association.private_data
}

moved {
  from = aws_cloudwatch_log_group.flow_logs
  to   = module.foundation.aws_cloudwatch_log_group.flow_logs
}

moved {
  from = aws_iam_role.flow_logs
  to   = module.foundation.aws_iam_role.flow_logs
}

moved {
  from = aws_iam_role_policy.flow_logs
  to   = module.foundation.aws_iam_role_policy.flow_logs
}

moved {
  from = aws_flow_log.vpc
  to   = module.foundation.aws_flow_log.vpc
}

moved {
  from = aws_secretsmanager_secret.app_runtime
  to   = module.data.aws_secretsmanager_secret.app_runtime
}

moved {
  from = aws_secretsmanager_secret.mongodb_atlas
  to   = module.data.aws_secretsmanager_secret.mongodb_atlas
}

moved {
  from = aws_security_group.alb
  to   = module.foundation.aws_security_group.alb
}

moved {
  from = aws_security_group.ecs
  to   = module.foundation.aws_security_group.ecs
}

moved {
  from = aws_security_group.api_gateway_vpc_link
  to   = module.foundation.aws_security_group.api_gateway_vpc_link
}

moved {
  from = aws_security_group_rule.alb_http_from_apigw_vpc_link
  to   = module.foundation.aws_security_group_rule.alb_http_from_apigw_vpc_link
}

moved {
  from = aws_security_group_rule.alb_to_ecs
  to   = module.foundation.aws_security_group_rule.alb_to_ecs
}

moved {
  from = aws_security_group_rule.ecs_from_alb
  to   = module.foundation.aws_security_group_rule.ecs_from_alb
}

moved {
  from = aws_security_group.docdb
  to   = module.foundation.aws_security_group.docdb
}

moved {
  from = aws_security_group.dms
  to   = module.foundation.aws_security_group.dms
}

moved {
  from = aws_security_group.efs
  to   = module.foundation.aws_security_group.efs
}

moved {
  from = aws_security_group.ops_runner
  to   = module.foundation.aws_security_group.ops_runner
}

moved {
  from = aws_security_group.vpc_endpoints
  to   = module.foundation.aws_security_group.vpc_endpoints
}

moved {
  from = aws_cloudwatch_log_group.rag_lambda
  to   = module.app.aws_cloudwatch_log_group.rag_lambda
}

moved {
  from = aws_cloudwatch_log_group.authorizer_lambda
  to   = module.app.aws_cloudwatch_log_group.authorizer_lambda
}

moved {
  from = aws_cloudwatch_log_group.sync_lambda
  to   = module.app.aws_cloudwatch_log_group.sync_lambda
}

moved {
  from = aws_lambda_function.rag
  to   = module.app.aws_lambda_function.rag
}

moved {
  from = aws_lambda_function.authorizer
  to   = module.app.aws_lambda_function.authorizer
}

moved {
  from = aws_lambda_function.sync
  to   = module.app.aws_lambda_function.sync
}

moved {
  from = aws_lambda_alias.rag_live
  to   = module.app.aws_lambda_alias.rag_live
}

moved {
  from = aws_lambda_provisioned_concurrency_config.rag
  to   = module.app.aws_lambda_provisioned_concurrency_config.rag
}

