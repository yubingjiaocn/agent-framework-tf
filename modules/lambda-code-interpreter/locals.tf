locals {
  # Computed function name
  function_name = "${var.name}-lambda-code-interpreter"

  # Computed role name
  role_name = "${var.name}-lambda-code-interpreter-role"

  # Source directory path
  source_directory = var.source_dir != "" ? var.source_dir : "${path.cwd}/src/lambda-code-interpreter"

  # Common tags
  common_tags = merge({
    Name        = local.function_name
    Module      = "lambda-code-interpreter"
  }, var.additional_tags)

  # Lambda environment variables
  lambda_env_vars = merge({
    PYTHONPATH = "/tmp"
  }, var.environment_variables)
}