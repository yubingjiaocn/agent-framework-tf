variable "name" {
  description = "Name prefix for resources"
  type        = string
  default     = "langfuse"
}

variable "domain" {
  description = "Domain name used for resource naming (e.g., company.com)"
  type        = string
}

variable "vpc_id" {
  description = "ID for VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_ids" {
  description = "Private subnet IDs from the VPC"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs from the VPC"
  type        = list(string)
}

variable "ecs_cluster_arn" {
  description = "ARN of the external ECS cluster"
  type        = string
}

variable "service_discovery_namespace_id" {
  description = "ID of the service discovery namespace"
  type        = string
}

variable "use_encryption_key" {
  description = "Whether to use an Encryption key for LLM API credential and integration credential store"
  type        = bool
  default     = true
}

variable "enable_clickhouse_log_tables" {
  description = "Whether to enable Clickhouse logging tables. Having them active produces a high base-load on the EFS filesystem."
  type        = bool
  default     = false
}

variable "postgres_instance_count" {
  description = "Number of PostgreSQL instances to create"
  type        = number
  default     = 1 # Default to 2 instances for high availability
}

variable "postgres_min_capacity" {
  description = "Minimum ACU capacity for PostgreSQL Serverless v2"
  type        = number
  default     = 0.5
}

variable "postgres_max_capacity" {
  description = "Maximum ACU capacity for PostgreSQL Serverless v2"
  type        = number
  default     = 2.0 # Higher default for production readiness
}

variable "postgres_version" {
  description = "PostgreSQL engine version to use"
  type        = string
  default     = "15.5"
}

variable "cache_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t4g.small"
}

variable "cache_instance_count" {
  description = "Number of ElastiCache instances used in the cluster"
  type        = number
  default     = 1
}

variable "clickhouse_instance_count" {
  description = "Number of ClickHouse instances used in the cluster"
  type        = number
  default     = 1
}

# Resource configuration variables
variable "langfuse_cpu" {
  description = "CPU allocation for Langfuse containers (in vCPU units: 256, 512, 1024, 2048, 4096)"
  type        = string
  default     = "1024"
  validation {
    condition     = contains(["256", "512", "1024", "2048", "4096"], var.langfuse_cpu)
    error_message = "CPU must be one of: 256, 512, 1024, 2048, 4096"
  }
}

variable "langfuse_memory" {
  description = "Memory allocation for Langfuse containers (in MB, must be compatible with CPU)"
  type        = string
  default     = "2048"
}

variable "langfuse_web_replicas" {
  description = "Number of replicas for Langfuse web container"
  type        = number
  default     = 1
  validation {
    condition     = var.langfuse_web_replicas > 0
    error_message = "There must be at least one Langfuse web replica."
  }
}

variable "langfuse_worker_replicas" {
  description = "Number of replicas for Langfuse worker container"
  type        = number
  default     = 1
  validation {
    condition     = var.langfuse_worker_replicas > 0
    error_message = "There must be at least one Langfuse worker replica."
  }
}

variable "clickhouse_replicas" {
  description = "Number of replicas of ClickHouse containers"
  type        = number
  default     = 1
}

variable "clickhouse_cpu" {
  description = "CPU allocation for ClickHouse containers (in vCPU units: 256, 512, 1024, 2048, 4096)"
  type        = string
  default     = "2048"
  validation {
    condition     = contains(["256", "512", "1024", "2048", "4096"], var.clickhouse_cpu)
    error_message = "CPU must be one of: 256, 512, 1024, 2048, 4096"
  }
}

variable "clickhouse_memory" {
  description = "Memory allocation for ClickHouse containers (in MB, must be compatible with CPU)"
  type        = string
  default     = "4096"
}

variable "alb_scheme" {
  description = "Scheme for the ALB (internal or internet-facing)"
  type        = string
  default     = "internal"
}

variable "ingress_inbound_cidrs" {
  description = "List of CIDR blocks allowed to access the ingress"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "redis_at_rest_encryption" {
  description = "Whether at-rest encryption is enabled for the Redis cluster"
  type        = bool
  default     = false
}

variable "redis_multi_az" {
  description = "Whether Multi-AZ is enabled for the Redis cluster"
  type        = bool
  default     = false
}

# Additional environment variables
variable "additional_env" {
  description = "Additional environment variables to set on Langfuse pods"
  type = list(object({
    name  = string
    value = optional(string)
    valueFrom = optional(object({
      secretKeyRef = optional(object({
        name = string
        key  = string
      }))
      configMapKeyRef = optional(object({
        name = string
        key  = string
      }))
    }))
  }))
  default = []

  validation {
    condition = alltrue([
      for env in var.additional_env :
      (env.value != null && env.valueFrom == null) || (env.value == null && env.valueFrom != null)
    ])
    error_message = "Each environment variable must have either 'value' or 'valueFrom' specified, but not both."
  }
}
