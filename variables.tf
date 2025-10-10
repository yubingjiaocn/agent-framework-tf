variable "name" {
  description = "Name of the stack"
  type = string
  default = "ai-agent"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "deploy_langfuse" {
  description = "Whether to deploy Langfuse"
  type = bool
  default = true
}

variable "deploy_mcp_gateway" {
  description = "Whether to deploy MCP Gateway (uses pre-built images from mcpgateway Docker Hub by default)"
  type        = bool
  default     = true
}