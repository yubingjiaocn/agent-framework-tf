module "lambda_code_interpreter" {
  count  = var.deploy_lambda_code_interpreter ? 1 : 0
  source = "./modules/lambda-code-interpreter"

  name       = "${var.name}-code-interpreter"
  source_dir = "./src/lambda-code-interpreter"

  # Optional: Configure Lambda resources
  memory_size            = 1024
  timeout                = 600
  ephemeral_storage_size = 512
}
