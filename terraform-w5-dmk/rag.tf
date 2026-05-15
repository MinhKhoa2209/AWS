data "archive_file" "rag_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/rag"
  output_path = "${path.module}/rag-lambda.zip"
}

resource "aws_cloudwatch_log_group" "rag_lambda" {
  name              = "/aws/lambda/${local.name_prefix}-rag"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.main.arn
}

resource "aws_lambda_function" "rag" {
  function_name    = "${local.name_prefix}-rag"
  role             = aws_iam_role.lambda.arn
  runtime          = "python3.12"
  handler          = "index.handler"
  filename         = data.archive_file.rag_lambda.output_path
  source_code_hash = data.archive_file.rag_lambda.output_base64sha256
  publish          = true
  timeout          = 30
  memory_size      = 512

  depends_on = [aws_cloudwatch_log_group.rag_lambda]
}

resource "aws_lambda_alias" "rag_live" {
  name             = "live"
  description      = "Live alias for provisioned concurrency"
  function_name    = aws_lambda_function.rag.function_name
  function_version = aws_lambda_function.rag.version
}

resource "aws_lambda_provisioned_concurrency_config" "rag" {
  function_name                     = aws_lambda_function.rag.function_name
  qualifier                         = aws_lambda_alias.rag_live.name
  provisioned_concurrent_executions = 1
}

resource "aws_api_gateway_rest_api" "rag" {
  name        = "${local.name_prefix}-rag-api"
  description = "REST API with API key for ${local.name_prefix} RAG Lambda"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "rag" {
  rest_api_id = aws_api_gateway_rest_api.rag.id
  parent_id   = aws_api_gateway_rest_api.rag.root_resource_id
  path_part   = "rag"
}

resource "aws_api_gateway_method" "rag_post" {
  rest_api_id      = aws_api_gateway_rest_api.rag.id
  resource_id      = aws_api_gateway_resource.rag.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "rag_post" {
  rest_api_id             = aws_api_gateway_rest_api.rag.id
  resource_id             = aws_api_gateway_resource.rag.id
  http_method             = aws_api_gateway_method.rag_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.rag.invoke_arn
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rag.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.rag.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "rag" {
  rest_api_id = aws_api_gateway_rest_api.rag.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.rag.id,
      aws_api_gateway_method.rag_post.id,
      aws_api_gateway_integration.rag_post.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "rag" {
  deployment_id = aws_api_gateway_deployment.rag.id
  rest_api_id   = aws_api_gateway_rest_api.rag.id
  stage_name    = "prod"
}

resource "aws_api_gateway_api_key" "rag" {
  name = "${local.name_prefix}-rag-api-key"
}

resource "aws_api_gateway_usage_plan" "rag" {
  name = "${local.name_prefix}-rag-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.rag.id
    stage  = aws_api_gateway_stage.rag.stage_name
  }

  throttle_settings {
    burst_limit = 20
    rate_limit  = 10
  }

  quota_settings {
    limit  = 1000
    period = "DAY"
  }
}

resource "aws_api_gateway_usage_plan_key" "rag" {
  key_id        = aws_api_gateway_api_key.rag.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.rag.id
}
