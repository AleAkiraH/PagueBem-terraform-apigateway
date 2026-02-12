output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = aws_apigatewayv2_stage.stage.invoke_url
}

output "api_id" {
  description = "API Gateway API ID"
  value       = aws_apigatewayv2_api.api.id
}

output "api_execution_arn" {
  description = "API Gateway execution ARN"
  value       = aws_apigatewayv2_api.api.execution_arn
}

output "stage_name" {
  description = "API Gateway stage name"
  value       = aws_apigatewayv2_stage.stage.name
}
