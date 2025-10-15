# Random password for PostgreSQL
# Using a alphanumeric password to avoid issues with special characters on bash entrypoint
resource "random_password" "postgres_password" {
  length      = 64
  special     = false
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
}

module "aurora_postgresql" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "~> 9.15.0"

  name           = "${var.name}-postgres"
  engine         = "aurora-postgresql"
  engine_mode    = "provisioned"
  engine_version = var.postgres_version

  database_name   = "langfuse"
  master_username = "langfuse"
  master_password = random_password.postgres_password.result
  manage_master_user_password = false

  # VPC Configuration
  vpc_id  = var.vpc_id
  subnets = var.private_subnet_ids

  create_db_subnet_group = true
  create_security_group  = true

  security_group_rules = {
    ingress_vpc = {
      type        = "ingress"
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "VPC traffic"
      cidr_blocks = [var.vpc_cidr]
    }
  }

  # Serverless v2 Configuration
  serverlessv2_scaling_configuration = {
    min_capacity = var.postgres_min_capacity
    max_capacity = var.postgres_max_capacity
  }

  # Instance Configuration
  instances = {
    for i in range(var.postgres_instance_count) : "instance-${i + 1}" => {
      instance_class = "db.serverless"
      performance_insights_enabled          = true
      performance_insights_retention_period = 7
    }
  }

  # Cluster Configuration
  skip_final_snapshot          = true
  storage_encrypted            = true
  backup_retention_period      = 7
  preferred_backup_window      = "03:00-04:00"
  preferred_maintenance_window = "mon:04:00-mon:05:00"

  # Parameter Group
  create_db_cluster_parameter_group = true
  db_cluster_parameter_group_family = "aurora-postgresql15"

  tags = {
    Name = local.tag_name
  }
}