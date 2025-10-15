# Random password for Redis
# Using a alphanumeric password to avoid issues with special characters on bash entrypoint
resource "random_password" "redis_password" {
  length      = 64
  special     = false
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
}

module "redis" {
  source  = "terraform-aws-modules/elasticache/aws"
  version = "~> 1.9.0"

  replication_group_id = var.name
  description          = "Valkey cluster for Langfuse"

  engine         = "valkey"
  engine_version = "7.2"
  node_type      = var.cache_node_type
  port           = 6379

  num_cache_clusters         = var.cache_instance_count
  automatic_failover_enabled = var.cache_instance_count > 1 ? true : false
  multi_az_enabled           = var.redis_multi_az

  # Authentication
  auth_token                 = random_password.redis_password.result
  transit_encryption_enabled = true
  at_rest_encryption_enabled = var.redis_at_rest_encryption

  # VPC and Security
  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  security_group_rules = {
    ingress_vpc = {
      description = "VPC traffic"
      cidr_ipv4   = var.vpc_cidr
    }
  }

  # Parameter Group
  create_parameter_group = true
  parameter_group_family = "valkey7"
  parameters = [
    {
      name  = "maxmemory-policy"
      value = "noeviction"
    }
  ]

  tags = {
    Name = local.tag_name
  }
}