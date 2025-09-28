# Lambda Code Interpreter Module - Main Configuration
# This module creates AWS Lambda function for Python code execution with dynamic module installation

# Create deployment package from source code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = local.source_directory
  output_path = "/tmp/${local.function_name}.zip"
}

# Lambda function using terraform-aws-modules/lambda/aws
module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.1"

  function_name = local.function_name
  description   = var.description
  handler       = "app.lambda_handler"
  runtime       = var.runtime
  architectures = [var.architecture]

  # Source configuration
  create_package = false
  local_existing_package = data.archive_file.lambda_zip.output_path

  # Resource configuration
  memory_size                    = var.memory_size
  timeout                       = var.timeout
  ephemeral_storage_size        = var.ephemeral_storage_size
  reserved_concurrent_executions = var.reserved_concurrent_executions

  # Environment variables
  environment_variables = local.lambda_env_vars

  # IAM configuration - always create role
  create_role                   = true
  role_name                     = local.role_name
  role_description              = "IAM role for ${local.function_name} Lambda function"
  role_tags                     = local.common_tags
  attach_policy_statements      = length(var.policy_statements) > 0
  policy_statements            = var.policy_statements
  attach_policies              = length(var.additional_policy_arns) > 0
  policies                     = var.additional_policy_arns
  number_of_policies           = length(var.additional_policy_arns)

  # VPC configuration
  vpc_subnet_ids         = var.vpc_config != null ? var.vpc_config.subnet_ids : null
  vpc_security_group_ids = var.vpc_config != null ? var.vpc_config.security_group_ids : null
  attach_network_policy  = var.vpc_config != null

  # CloudWatch Logs
  cloudwatch_logs_retention_in_days = var.cloudwatch_logs_retention_in_days

  # Function URL - disabled
  create_lambda_function_url = false

  # Tracing
  tracing_mode = var.tracing_mode

  # Tags
  tags = local.common_tags
}
