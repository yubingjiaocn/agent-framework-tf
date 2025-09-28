# Lambda Code Interpreter Module Outputs

# Lambda Function outputs
output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.lambda_function.lambda_function_arn
}

# IAM Role outputs
output "lambda_role_arn" {
  description = "ARN of the IAM role for the Lambda function"
  value       = module.lambda_function.lambda_role_arn
}
