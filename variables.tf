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
