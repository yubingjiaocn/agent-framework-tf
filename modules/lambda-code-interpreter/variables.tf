# Lambda Code Interpreter Module Variables

# Required Variables
variable "name" {
  description = "Name prefix for Lambda Code Interpreter resources"
  type        = string
}

variable "description" {
  description = "Description of the Lambda function"
  type        = string
  default     = "Lambda function to run Python code with dynamic module installation"
}

variable "runtime" {
  description = "Lambda runtime version"
  type        = string
  default     = "python3.13"
  validation {
    condition     = contains(["python3.9", "python3.10", "python3.11", "python3.12", "python3.13"], var.runtime)
    error_message = "Runtime must be a supported Python version."
  }
}

variable "architecture" {
  description = "Lambda function architecture"
  type        = string
  default     = "arm64"
  validation {
    condition     = contains(["x86_64", "arm64"], var.architecture)
    error_message = "Architecture must be either x86_64 or arm64."
  }
}

variable "memory_size" {
  description = "Memory allocation for Lambda function (MB)"
  type        = number
  default     = 1024
  validation {
    condition     = var.memory_size >= 128 && var.memory_size <= 10240
    error_message = "Memory size must be between 128 MB and 10,240 MB."
  }
}

variable "timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 600
  validation {
    condition     = var.timeout >= 1 && var.timeout <= 900
    error_message = "Timeout must be between 1 and 900 seconds."
  }
}

variable "ephemeral_storage_size" {
  description = "Ephemeral storage size for Lambda function (/tmp directory) in MB"
  type        = number
  default     = 512
  validation {
    condition     = var.ephemeral_storage_size >= 512 && var.ephemeral_storage_size <= 10240
    error_message = "Ephemeral storage size must be between 512 MB and 10,240 MB."
  }
}

# Source Code Configuration
variable "source_dir" {
  description = "Path to the source code directory containing app.py"
  type        = string
  default     = "../../src/lambda-code-interpreter"
}

variable "additional_policy_arns" {
  description = "List of additional IAM policy ARNs to attach to the Lambda role"
  type        = list(string)
  default     = []
}

variable "policy_statements" {
  description = "Map of IAM policy statements to attach to the Lambda role"
  type        = any
  default     = {}
}


variable "reserved_concurrent_executions" {
  description = "Amount of reserved concurrent executions for this Lambda function"
  type        = number
  default     = -1
}

# Environment Variables
variable "environment_variables" {
  description = "Environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

# VPC Configuration (Optional)
variable "vpc_config" {
  description = "VPC configuration for Lambda function"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

# Logging Configuration
variable "cloudwatch_logs_retention_in_days" {
  description = "CloudWatch Logs retention period in days"
  type        = number
  default     = 14
  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653
    ], var.cloudwatch_logs_retention_in_days)
    error_message = "CloudWatch Logs retention period must be a valid value."
  }
}

variable "tracing_mode" {
  description = "X-Ray tracing mode (Active, PassThrough)"
  type        = string
  default     = null
  validation {
    condition     = var.tracing_mode == null || contains(["Active", "PassThrough"], var.tracing_mode)
    error_message = "Tracing mode must be either Active or PassThrough."
  }
}

# Tags

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
