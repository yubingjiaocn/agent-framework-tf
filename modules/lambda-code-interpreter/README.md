# Lambda Code Interpreter Terraform Module

This module creates an AWS Lambda function for executing Python code with dynamic module installation capabilities. It's designed for scenarios where you need to run arbitrary Python code with the ability to install packages at runtime.

## Features

- **Python Code Execution**: Execute arbitrary Python scripts via Lambda
- **Dynamic Module Installation**: Install Python packages at runtime using pip
- **Image Processing**: Automatically encode generated images (PNG, JPEG, etc.) to base64
- **Flexible Runtime**: Support for Python 3.9-3.13 runtimes
- **ARM64 Architecture**: Optimized for ARM64 (Graviton2) by default for better price/performance
- **Comprehensive IAM**: Configurable IAM roles and policies
- **VPC Support**: Optional VPC configuration for secure networking
- **Function URLs**: Optional HTTP endpoints for direct invocation
- **X-Ray Tracing**: Optional distributed tracing support

## Usage

### Basic Example

```hcl
module "lambda_code_interpreter" {
  source = "./modules/lambda-code-interpreter"

  name        = "my-project"
  description = "Python code interpreter for dynamic execution"
}
```

### Advanced Example

```hcl
module "lambda_code_interpreter" {
  source = "./modules/lambda-code-interpreter"

  name         = "my-project"
  description  = "Python code interpreter with custom configuration"
  runtime      = "python3.13"
  memory_size  = 2048
  timeout      = 300

  # Custom source directory
  source_dir = "${path.module}/../../src/lambda-code-interpreter"

  # Environment variables
  environment_variables = {
    CUSTOM_VAR = "value"
    LOG_LEVEL  = "DEBUG"
  }

  # VPC configuration
  vpc_config = {
    subnet_ids         = ["subnet-12345", "subnet-67890"]
    security_group_ids = ["sg-abcdef"]
  }

  # Function URL for HTTP access
  create_function_url = true
  function_url_config = {
    authorization_type = "AWS_IAM"
    cors = {
      allow_origins = ["*"]
      allow_methods = ["POST"]
      max_age       = 300
    }
  }

  # Additional IAM policies
  additional_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  ]

  # Custom policy statements
  policy_statements = {
    dynamodb_read = {
      effect = "Allow"
      actions = [
        "dynamodb:GetItem",
        "dynamodb:Query"
      ]
      resources = ["arn:aws:dynamodb:*:*:table/my-table"]
    }
  }

  tags = {
    Environment = "production"
    Project     = "ai-tools"
  }
}
```

## Lambda Function Interface

The Lambda function accepts the following input format:

```json
{
  "input_script": "print('Hello, World!')\nimport matplotlib.pyplot as plt\nplt.plot([1,2,3])\nplt.savefig('/tmp/plot.png')",
  "install_modules": ["matplotlib", "numpy", "pandas"]
}
```

And returns:

```json
{
  "statusCode": 200,
  "body": {
    "output": "Hello, World!\nFile /tmp/plot.png loaded.\n",
    "images": [
      {
        "path": "/tmp/plot.png",
        "base64": "iVBORw0KGgoAAAANSUhEUgAA..."
      }
    ]
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |
| archive | >= 2.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0 |
| archive | >= 2.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| lambda_function | terraform-aws-modules/lambda/aws | ~> 8.1 |

## Resources

| Name | Type |
|------|------|
| archive_file.lambda_zip | data source |
| aws_cloudwatch_log_group.lambda_logs | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name prefix for Lambda Code Interpreter resources | `string` | n/a | yes |
| additional_policy_arns | List of additional IAM policy ARNs to attach to the Lambda role | `list(string)` | `[]` | no |
| additional_tags | Additional tags to apply to all resources | `map(string)` | `{}` | no |
| architecture | Lambda function architecture | `string` | `"arm64"` | no |
| cloudwatch_logs_log_group_class | CloudWatch Logs log group class | `string` | `null` | no |
| cloudwatch_logs_retention_in_days | CloudWatch Logs retention period in days | `number` | `14` | no |
| create_custom_log_group | Whether to create a custom CloudWatch log group (for advanced configuration) | `bool` | `false` | no |
| create_function_url | Whether to create a Lambda function URL | `bool` | `false` | no |
| create_role | Whether to create a new IAM role for the Lambda function | `bool` | `true` | no |
| create_zip_from_source | Whether to create deployment package from source directory | `bool` | `true` | no |
| dead_letter_config | Dead letter queue configuration | `object` | `null` | no |
| description | Description of the Lambda function | `string` | `"Lambda function to run Python code with dynamic module installation"` | no |
| environment | Environment name (dev, staging, prod) | `string` | `"prod"` | no |
| environment_variables | Environment variables for the Lambda function | `map(string)` | `{}` | no |
| ephemeral_storage_size | Ephemeral storage size for Lambda function (/tmp directory) in MB | `number` | `512` | no |
| function_name | Name of the Lambda function | `string` | `""` | no |
| function_url_config | Lambda function URL configuration | `object` | `{ authorization_type = "AWS_IAM" }` | no |
| memory_size | Memory allocation for Lambda function (MB) | `number` | `1024` | no |
| policy_statements | Map of IAM policy statements to attach to the Lambda role | `any` | `{}` | no |
| reserved_concurrent_executions | Amount of reserved concurrent executions for this Lambda function | `number` | `-1` | no |
| role_arn | ARN of existing IAM role to use (required when create_role is false) | `string` | `""` | no |
| role_name | Name of the IAM role to create (when create_role is true) | `string` | `""` | no |
| role_permissions_boundary | ARN of the permissions boundary policy to attach to the Lambda role | `string` | `null` | no |
| runtime | Lambda runtime version | `string` | `"python3.13"` | no |
| source_dir | Path to the source code directory containing app.py | `string` | `""` | no |
| timeout | Lambda function timeout in seconds | `number` | `600` | no |
| tracing_mode | X-Ray tracing mode (Active, PassThrough) | `string` | `null` | no |
| vpc_config | VPC configuration for Lambda function | `object` | `null` | no |
| zip_file_path | Path to pre-built deployment package zip file (used when create_zip_from_source is false) | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| lambda_cloudwatch_log_group_arn | ARN of the CloudWatch Log Group for the Lambda function |
| lambda_cloudwatch_log_group_name | Name of the CloudWatch Log Group for the Lambda function |
| lambda_dead_letter_queue_arn | ARN of the dead letter queue |
| lambda_function_arn | ARN of the Lambda function |
| lambda_function_invoke_arn | Invoke ARN of the Lambda function |
| lambda_function_kms_key_arn | KMS key ARN used to encrypt Lambda function environment variables |
| lambda_function_last_modified | Date the Lambda function was last modified |
| lambda_function_name | Name of the Lambda function |
| lambda_function_qualified_arn | Qualified ARN of the Lambda function |
| lambda_function_source_code_hash | Base64-encoded SHA256 hash of the package file |
| lambda_function_source_code_size | Size in bytes of the function .zip file |
| lambda_function_url | Lambda function URL |
| lambda_function_url_id | Lambda function URL ID |
| lambda_function_version | Version of the Lambda function |
| lambda_role_arn | ARN of the IAM role for the Lambda function |
| lambda_role_name | Name of the IAM role for the Lambda function |
| lambda_role_unique_id | Unique ID of the IAM role for the Lambda function |
| local_filename | Local filename of the Lambda deployment package |
| s3_bucket | S3 bucket containing the Lambda deployment package (if applicable) |
| s3_key | S3 key of the Lambda deployment package (if applicable) |
| s3_object_version | S3 object version of the Lambda deployment package (if applicable) |

## License

Apache 2 Licensed. See LICENSE for full details.