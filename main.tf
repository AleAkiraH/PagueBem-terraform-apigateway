terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "paguebem-terraform-state"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
    # key é passado via -backend-config="key=..." no terraform init
    # Dev:  apigateway/dev/terraform.tfstate
    # Prod: apigateway/prod/terraform.tfstate
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Repository  = "PagueBem-terraform-apigateway"
    }
  }
}

# =============================================================================
# API Gateway HTTP API v2
# =============================================================================
resource "aws_apigatewayv2_api" "api" {
  name          = "${var.project_name}-api-${var.environment}"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = var.cors_allow_origins
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization"]
    max_age       = 3600
  }

  tags = {
    Name = "${var.project_name}-api-${var.environment}"
  }
}

# =============================================================================
# Lambda Integration
# =============================================================================
resource "aws_apigatewayv2_integration" "lambda" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = var.lambda_invoke_arn
  integration_method = "POST"
}

# =============================================================================
# Default Route (catch-all)
# =============================================================================
resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# =============================================================================
# Stage
# =============================================================================
resource "aws_apigatewayv2_stage" "stage" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = var.environment
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      method         = "$context.httpMethod"
      path           = "$context.path"
      status         = "$context.status"
      responseLength = "$context.responseLength"
      integrationErr = "$context.integrationErrorMessage"
    })
  }

  tags = {
    Name = "${var.project_name}-api-${var.environment}-stage"
  }
}

# =============================================================================
# CloudWatch Log Group for API Gateway
# =============================================================================
resource "aws_cloudwatch_log_group" "api" {
  name              = "/aws/apigateway/${var.project_name}-api-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.project_name}-api-${var.environment}-apigw-logs"
  }
}

# =============================================================================
# Lambda Permission (allow API Gateway to invoke Lambda)
# =============================================================================
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowExecutionFromAPIGW"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}
