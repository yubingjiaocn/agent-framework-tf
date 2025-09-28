module "langfuse" {
  source = "./modules/langfuse-terraform-aws"

  domain = "langfuse.example.com"

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets
  public_subnet_ids  = module.vpc.public_subnets
  vpc_cidr          = module.vpc.vpc_cidr_block

  # ECS Cluster configuration
  ecs_cluster_arn                 = module.ecs_cluster.arn
  service_discovery_namespace_id  = aws_service_discovery_private_dns_namespace.main.id

  # Optional use a different name for your installation
  # e.g. when using the module multiple times on the same AWS account
  name = "${var.name}-langfuse"

  # Optional: Configure Langfuse
  use_encryption_key = false # Enable encryption for sensitive data stored in Langfuse

  # Optional: Configure the database instances
  postgres_instance_count = 2
  postgres_min_capacity   = 0.5
  postgres_max_capacity   = 2.0

  # Optional: Configure the cache
  cache_node_type      = "cache.t4g.small"
  cache_instance_count = 2

}

# Note: This module now uses ECS instead of EKS for container orchestration
# No additional provider configuration is required for ECS deployment
