terraform {
  required_providers {
    archive = {
      source = "hashicorp/archive"
    }
    aws = {
      source = "hashicorp/aws"
    }
  }
}

locals {
  backend_environment = {
    NODE_ENV                          = "production"
    PORT                              = tostring(var.backend_container_port)
    AWS_REGION                        = var.aws_region
    APP_ORIGIN                        = var.app_origin
    GOOGLE_CLIENT_ID                  = var.google_client_id
    AI_MICROSERVICE_URL               = var.ai_microservice_url
    RAG_API_URL                       = "${aws_apigatewayv2_stage.default.invoke_url}rag"
    RAG_LAMBDA_URL                    = "${aws_apigatewayv2_stage.default.invoke_url}rag"
    MEDIA_BUCKET_NAME                 = var.media_bucket
    KNOWLEDGE_BASE_SOURCE_BUCKET_NAME = var.knowledge_base_source_bucket
    EFS_SHARED_PATH                   = "/mnt/shared"
    DOCDB_DATABASE_NAME               = var.documentdb_database_name
    DOCDB_SECRET_ARN                  = var.documentdb_cluster_arn == null ? "" : var.documentdb_master_secret_arn
    APP_RUNTIME_SECRET_ARN            = var.app_runtime_secret_arn
    COGNITO_USER_POOL_ID              = var.cognito_user_pool_id
    COGNITO_USER_POOL_CLIENT_ID       = var.cognito_user_pool_client_id
  }
}

data "aws_iam_policy_document" "ecs_task_execution_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "backup_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "dms_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["dms.${var.aws_region}.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "scheduler_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution" {
  name               = "${var.name_prefix}-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_assume.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task" {
  name               = "${var.name_prefix}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_assume.json
}

resource "aws_iam_role_policy" "ecs_task_app" {
  name = "${var.name_prefix}-ecs-task-app-policy"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite"
        ]
        Resource = var.efs_arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.ecs.arn}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.media_bucket_arn,
          "${var.media_bucket_arn}/*",
          var.knowledge_base_source_bucket_arn,
          "${var.knowledge_base_source_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          var.app_runtime_secret_arn,
          var.documentdb_master_secret_arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "cognito-idp:AdminCreateUser",
          "cognito-idp:AdminGetUser",
          "cognito-idp:AdminSetUserPassword",
          "cognito-idp:AdminUpdateUserAttributes",
          "cognito-idp:ChangePassword",
          "cognito-idp:ConfirmForgotPassword",
          "cognito-idp:ConfirmSignUp",
          "cognito-idp:ForgotPassword",
          "cognito-idp:GetUser",
          "cognito-idp:InitiateAuth",
          "cognito-idp:ResendConfirmationCode",
          "cognito-idp:RevokeToken",
          "cognito-idp:SignUp"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ]
        Resource = var.kms_key_arn
      }
    ]
  })
}

resource "aws_iam_role" "lambda" {
  name               = "${var.name_prefix}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_bedrock" {
  name = "${var.name_prefix}-lambda-bedrock-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy" "lambda_storage" {
  name = "${var.name_prefix}-lambda-storage-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.media_bucket_arn,
          "${var.media_bucket_arn}/*",
          var.knowledge_base_source_bucket_arn,
          "${var.knowledge_base_source_bucket_arn}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = "lambda:InvokeFunction"
        Resource = aws_lambda_function.rag.arn
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ]
        Resource = var.kms_key_arn
      }
    ]
  })
}

resource "aws_iam_role" "ops_runner" {
  name               = "${var.name_prefix}-ops-runner-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_role_policy_attachment" "ops_runner_ssm" {
  role       = aws_iam_role.ops_runner.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ops_runner" {
  name = "${var.name_prefix}-ops-runner-profile"
  role = aws_iam_role.ops_runner.name
}

resource "aws_iam_role" "backup" {
  name               = "${var.name_prefix}-backup-role"
  assume_role_policy = data.aws_iam_policy_document.backup_assume.json
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role" "dms_secrets" {
  count              = var.enable_dms ? 1 : 0
  name               = "${var.name_prefix}-dms-secrets-role"
  assume_role_policy = data.aws_iam_policy_document.dms_assume.json
}

resource "aws_iam_role_policy" "dms_secrets" {
  count = var.enable_dms ? 1 : 0
  name  = "${var.name_prefix}-dms-secrets-policy"
  role  = aws_iam_role.dms_secrets[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "kms:Decrypt"
      ]
      Resource = [
        var.mongodb_atlas_secret_arn,
        var.documentdb_master_secret_arn,
        var.kms_key_arn
      ]
    }]
  })
}

resource "aws_iam_role" "auto_shutdown" {
  count              = var.enable_auto_shutdown ? 1 : 0
  name               = "${var.name_prefix}-auto-shutdown-role"
  assume_role_policy = data.aws_iam_policy_document.scheduler_assume.json
}

resource "aws_iam_role_policy" "auto_shutdown" {
  count = var.enable_auto_shutdown ? 1 : 0
  name  = "${var.name_prefix}-auto-shutdown-policy"
  role  = aws_iam_role.auto_shutdown[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "ecs:UpdateService"
      Resource = aws_ecs_service.backend.id
    }]
  })
}

data "archive_file" "rag_lambda" {
  type        = "zip"
  source_dir  = "${path.root}/lambda/rag"
  output_path = "${path.module}/rag-lambda.zip"
}

data "archive_file" "authorizer_lambda" {
  type        = "zip"
  source_dir  = "${path.root}/lambda/authorizer"
  output_path = "${path.module}/authorizer-lambda.zip"
}

data "archive_file" "sync_lambda" {
  type        = "zip"
  source_dir  = "${path.root}/lambda/sync"
  output_path = "${path.module}/sync-lambda.zip"
}

resource "aws_cloudwatch_log_group" "rag_lambda" {
  name              = "/aws/lambda/${var.name_prefix}-rag"
  retention_in_days = 14
  kms_key_id        = var.kms_key_arn
}

resource "aws_cloudwatch_log_group" "authorizer_lambda" {
  name              = "/aws/lambda/${var.name_prefix}-authorizer"
  retention_in_days = 14
  kms_key_id        = var.kms_key_arn
}

resource "aws_cloudwatch_log_group" "sync_lambda" {
  name              = "/aws/lambda/${var.name_prefix}-sync"
  retention_in_days = 14
  kms_key_id        = var.kms_key_arn
}

resource "aws_lambda_function" "rag" {
  function_name    = "${var.name_prefix}-rag"
  role             = aws_iam_role.lambda.arn
  runtime          = "python3.12"
  handler          = "index.handler"
  filename         = data.archive_file.rag_lambda.output_path
  source_code_hash = data.archive_file.rag_lambda.output_base64sha256
  publish          = true
  timeout          = 30
  memory_size      = 512

  environment {
    variables = {
      BEDROCK_MODEL_ID = var.bedrock_model_id
    }
  }

  depends_on = [aws_cloudwatch_log_group.rag_lambda]
}

resource "aws_lambda_function" "authorizer" {
  function_name    = "${var.name_prefix}-authorizer"
  role             = aws_iam_role.lambda.arn
  runtime          = "python3.12"
  handler          = "index.handler"
  filename         = data.archive_file.authorizer_lambda.output_path
  source_code_hash = data.archive_file.authorizer_lambda.output_base64sha256
  publish          = true
  timeout          = 10
  memory_size      = 128

  depends_on = [aws_cloudwatch_log_group.authorizer_lambda]
}

resource "aws_lambda_function" "sync" {
  function_name    = "${var.name_prefix}-sync"
  role             = aws_iam_role.lambda.arn
  runtime          = "python3.12"
  handler          = "index.handler"
  filename         = data.archive_file.sync_lambda.output_path
  source_code_hash = data.archive_file.sync_lambda.output_base64sha256
  publish          = true
  timeout          = 60
  memory_size      = 512

  environment {
    variables = {
      BEDROCK_MODEL_ID                  = var.bedrock_model_id
      RAG_FUNCTION_NAME                 = aws_lambda_function.rag.function_name
      MEDIA_BUCKET_NAME                 = var.media_bucket
      KNOWLEDGE_BASE_SOURCE_BUCKET_NAME = var.knowledge_base_source_bucket
    }
  }

  depends_on = [aws_cloudwatch_log_group.sync_lambda]
}

resource "aws_lambda_alias" "rag_live" {
  name             = "live"
  description      = "Live alias for optional provisioned concurrency"
  function_name    = aws_lambda_function.rag.function_name
  function_version = aws_lambda_function.rag.version
}

resource "aws_lambda_provisioned_concurrency_config" "rag" {
  count                             = var.enable_lambda_provisioned_concurrency ? 1 : 0
  function_name                     = aws_lambda_function.rag.function_name
  qualifier                         = aws_lambda_alias.rag_live.name
  provisioned_concurrent_executions = 1
}

resource "aws_ecr_repository" "backend" {
  name                 = "${var.name_prefix}-be"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.kms_key_arn
  }
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.name_prefix}/backend"
  retention_in_days = 14
  kms_key_id        = var.kms_key_arn
}

resource "aws_lb" "backend" {
  name               = "${var.name_prefix}-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.private_app_subnet_ids

  tags = {
    Name = "${var.name_prefix}-alb"
  }
}

resource "aws_lb_target_group" "backend" {
  name        = "${var.name_prefix}-tg"
  port        = var.backend_container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/api/health"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.backend.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}

resource "aws_ecs_cluster" "main" {
  name = "${var.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_apigatewayv2_api" "main" {
  name          = "${var.name_prefix}-http-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_credentials = true
    allow_headers     = ["authorization", "content-type", "x-requested-with"]
    allow_methods     = ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
    allow_origins     = [var.app_origin]
    max_age           = 300
  }
}

resource "aws_apigatewayv2_vpc_link" "backend" {
  name               = "${var.name_prefix}-alb-vpc-link"
  security_group_ids = [var.api_gateway_vpc_link_security_group_id]
  subnet_ids         = var.private_app_subnet_ids
}

resource "aws_apigatewayv2_authorizer" "lambda" {
  api_id                            = aws_apigatewayv2_api.main.id
  authorizer_type                   = "REQUEST"
  authorizer_uri                    = aws_lambda_function.authorizer.invoke_arn
  authorizer_payload_format_version = "2.0"
  authorizer_result_ttl_in_seconds  = 0
  enable_simple_responses           = true
  name                              = "${var.name_prefix}-lambda-authorizer"
}

resource "aws_apigatewayv2_integration" "backend" {
  api_id             = aws_apigatewayv2_api.main.id
  connection_id      = aws_apigatewayv2_vpc_link.backend.id
  connection_type    = "VPC_LINK"
  integration_method = "ANY"
  integration_type   = "HTTP_PROXY"
  integration_uri    = aws_lb_listener.http.arn
}

resource "aws_apigatewayv2_integration" "rag" {
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.rag.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "api_proxy" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "ANY /api/{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.backend.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.lambda.id
}

resource "aws_apigatewayv2_route" "auth_login" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /api/auth/login"
  target    = "integrations/${aws_apigatewayv2_integration.backend.id}"
}

resource "aws_apigatewayv2_route" "auth_register" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /api/auth/register"
  target    = "integrations/${aws_apigatewayv2_integration.backend.id}"
}

resource "aws_apigatewayv2_route" "auth_google" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /api/auth/google"
  target    = "integrations/${aws_apigatewayv2_integration.backend.id}"
}

resource "aws_apigatewayv2_route" "auth_refresh" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /api/auth/refresh"
  target    = "integrations/${aws_apigatewayv2_integration.backend.id}"
}

resource "aws_apigatewayv2_route" "auth_verify_email" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /api/auth/verify-email"
  target    = "integrations/${aws_apigatewayv2_integration.backend.id}"
}

resource "aws_apigatewayv2_route" "auth_resend_verify_email" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /api/auth/resend-verify-email"
  target    = "integrations/${aws_apigatewayv2_integration.backend.id}"
}

resource "aws_apigatewayv2_route" "auth_password_forgot" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /api/auth/password/forgot"
  target    = "integrations/${aws_apigatewayv2_integration.backend.id}"
}

resource "aws_apigatewayv2_route" "auth_password_verify_otp" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /api/auth/password/verify-otp"
  target    = "integrations/${aws_apigatewayv2_integration.backend.id}"
}

resource "aws_apigatewayv2_route" "auth_password_reset" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /api/auth/password/reset"
  target    = "integrations/${aws_apigatewayv2_integration.backend.id}"
}

resource "aws_apigatewayv2_route" "socket_proxy" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "ANY /socket.io/{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.backend.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.lambda.id
}

resource "aws_apigatewayv2_route" "rag_post" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /rag"
  target    = "integrations/${aws_apigatewayv2_integration.rag.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = 20
    throttling_rate_limit  = 10
  }
}

resource "aws_lambda_permission" "http_api_rag" {
  statement_id  = "AllowExecutionFromHttpApiRag"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rag.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "http_api_authorizer" {
  statement_id  = "AllowExecutionFromHttpApiAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.authorizer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/authorizers/${aws_apigatewayv2_authorizer.lambda.id}"
}

resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.name_prefix}-backend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.backend_cpu
  memory                   = var.backend_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  volume {
    name = "shared"

    efs_volume_configuration {
      file_system_id     = var.efs_id
      transit_encryption = "ENABLED"
    }
  }

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = "${aws_ecr_repository.backend.repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = var.backend_container_port
          hostPort      = var.backend_container_port
          protocol      = "tcp"
        }
      ]

      mountPoints = [
        {
          sourceVolume  = "shared"
          containerPath = "/mnt/shared"
          readOnly      = false
        }
      ]

      environment = [
        for key, value in local.backend_environment : {
          name  = key
          value = value
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "backend"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "backend" {
  name                   = "${var.name_prefix}-backend-service"
  cluster                = aws_ecs_cluster.main.id
  task_definition        = aws_ecs_task_definition.backend.arn
  desired_count          = var.backend_desired_count
  launch_type            = "FARGATE"
  enable_execute_command = true
  wait_for_steady_state  = false

  network_configuration {
    subnets          = var.private_app_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "backend"
    container_port   = var.backend_container_port
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  depends_on = [aws_lb_listener.http]
}

resource "aws_scheduler_schedule" "ecs_auto_shutdown" {
  count                        = var.enable_auto_shutdown ? 1 : 0
  name                         = "${var.name_prefix}-ecs-auto-shutdown"
  description                  = "Scale ${var.name_prefix} ECS backend service to zero"
  schedule_expression          = "at(${var.auto_shutdown_at_utc})"
  schedule_expression_timezone = "UTC"
  state                        = "ENABLED"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ecs:updateService"
    role_arn = aws_iam_role.auto_shutdown[0].arn

    input = jsonencode({
      Cluster      = aws_ecs_cluster.main.name
      Service      = aws_ecs_service.backend.name
      DesiredCount = 0
    })
  }

  depends_on = [aws_iam_role_policy.auto_shutdown]
}

resource "aws_lambda_permission" "knowledge_base_source_sync" {
  statement_id  = "AllowKnowledgeBaseSourceBucketInvokeSync"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sync.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.knowledge_base_source_bucket_arn
}

resource "aws_s3_bucket_notification" "knowledge_base_source" {
  bucket = var.knowledge_base_source_bucket

  lambda_function {
    lambda_function_arn = aws_lambda_function.sync.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.knowledge_base_source_sync]
}

data "aws_ami" "amazon_linux" {
  count       = var.enable_ops_runner ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "ops_runner" {
  count                       = var.enable_ops_runner ? 1 : 0
  ami                         = data.aws_ami.amazon_linux[0].id
  instance_type               = var.ops_runner_instance_type
  subnet_id                   = var.private_app_subnet_ids[0]
  vpc_security_group_ids      = [var.ops_runner_security_group_id]
  iam_instance_profile        = aws_iam_instance_profile.ops_runner.name
  associate_public_ip_address = false

  root_block_device {
    encrypted   = true
    volume_size = 20
    volume_type = "gp3"
    kms_key_id  = var.kms_key_arn
  }

  user_data = templatefile("${path.root}/templates/ops-runner-user-data.sh.tftpl", {
    efs_id     = var.efs_id
    aws_region = var.aws_region
  })

  tags = {
    Name = "${var.name_prefix}-ops-runner"
  }
}

resource "aws_backup_vault" "main" {
  count       = var.enable_backup ? 1 : 0
  name        = "${var.name_prefix}-backup-vault"
  kms_key_arn = var.kms_key_arn
}

resource "aws_backup_plan" "main" {
  count = var.enable_backup ? 1 : 0
  name  = "${var.name_prefix}-backup-plan"

  rule {
    rule_name         = "daily"
    target_vault_name = aws_backup_vault.main[0].name
    schedule          = "cron(0 17 ? * * *)"

    lifecycle {
      delete_after = 7
    }
  }
}

resource "aws_backup_selection" "main" {
  count        = var.enable_backup ? 1 : 0
  iam_role_arn = aws_iam_role.backup.arn
  name         = "${var.name_prefix}-backup-selection"
  plan_id      = aws_backup_plan.main[0].id

  resources = concat(
    [
      var.efs_arn,
      var.documentdb_cluster_arn
    ],
    var.enable_ops_runner ? [aws_instance.ops_runner[0].arn] : []
  )
}

resource "aws_dms_replication_subnet_group" "main" {
  count = var.enable_dms ? 1 : 0

  replication_subnet_group_description = "DMS subnet group for ${var.name_prefix}"
  replication_subnet_group_id          = "${var.name_prefix}-dms-subnet-group"
  subnet_ids                           = var.private_app_subnet_ids
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
  replication_instance_id     = "${var.name_prefix}-dms"
  replication_subnet_group_id = aws_dms_replication_subnet_group.main[0].id
  vpc_security_group_ids      = [var.dms_security_group_id]
  kms_key_arn                 = var.kms_key_arn
}

resource "aws_dms_certificate" "docdb" {
  count = var.enable_dms ? 1 : 0

  certificate_id  = "${var.name_prefix}-docdb-ca"
  certificate_pem = file("${path.root}/global-bundle.pem")
}

resource "aws_dms_endpoint" "mongodb_atlas_source" {
  count = var.enable_dms ? 1 : 0

  endpoint_id                     = "${var.name_prefix}-mongodb-atlas-source"
  endpoint_type                   = "source"
  engine_name                     = "mongodb"
  secrets_manager_access_role_arn = aws_iam_role.dms_secrets[0].arn
  secrets_manager_arn             = var.mongodb_atlas_secret_arn
  ssl_mode                        = "require"

  mongodb_settings {
    auth_mechanism      = "default"
    auth_source         = var.mongodb_atlas_auth_source
    auth_type           = "password"
    docs_to_investigate = "1000"
    extract_doc_id      = "true"
    nesting_level       = "none"
  }

  depends_on = [aws_iam_role_policy.dms_secrets]
}

resource "aws_dms_endpoint" "docdb_target" {
  count = var.enable_dms ? 1 : 0

  endpoint_id                     = "${var.name_prefix}-docdb-target"
  endpoint_type                   = "target"
  engine_name                     = "docdb"
  database_name                   = var.documentdb_database_name
  certificate_arn                 = aws_dms_certificate.docdb[0].certificate_arn
  secrets_manager_access_role_arn = aws_iam_role.dms_secrets[0].arn
  secrets_manager_arn             = var.documentdb_master_secret_arn
  ssl_mode                        = "verify-full"

  depends_on = [aws_iam_role_policy.dms_secrets]
}

resource "aws_dms_replication_task" "mongodb_to_docdb" {
  count = var.enable_dms ? 1 : 0

  migration_type           = var.dms_migration_type
  replication_instance_arn = aws_dms_replication_instance.main[0].replication_instance_arn
  replication_task_id      = "${var.name_prefix}-mongodb-to-docdb"
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
