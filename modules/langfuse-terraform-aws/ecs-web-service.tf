# Langfuse Web Service
module "ecs_service_web" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 6.0"

  name         = "${var.name}-web"
  cluster_arn  = var.ecs_cluster_arn
  cpu          = var.langfuse_cpu
  memory       = var.langfuse_memory
  desired_count = var.langfuse_web_replicas
  enable_autoscaling = false

  requires_compatibilities = ["FARGATE"]
  capacity_provider_strategy = {
    FARGATE = {
      capacity_provider = "FARGATE"
      weight = 100
      base   = 1
    }
  }

  # Task roles
  create_task_exec_iam_role = true
  task_exec_iam_role_policies = {
    SecretsManagerAccess = aws_iam_policy.ecs_secrets_access.arn
  }
  create_tasks_iam_role   = true
  tasks_iam_role_policies = {
    S3Access = aws_iam_policy.ecs_s3_access.arn
    SecretsManagerAccess = aws_iam_policy.ecs_secrets_access.arn
  }

  # Container definitions
  container_definitions = {
    langfuse-web = {
      cpu       = tonumber(var.langfuse_cpu)
      memory    = tonumber(var.langfuse_memory)
      essential = true
      image     = "docker.io/langfuse/langfuse:3"

      portMappings = [
        {
          name           = "langfuse-web"
          containerPort = 3000
          protocol       = "tcp"
        }
      ]

      environment = [
        {
          name  = "NEXTAUTH_URL"
          value = "https://${module.alb.dns_name}"
        },
        {
          name  = "TELEMETRY_ENABLED"
          value = "true"
        },
        {
          name  = "LANGFUSE_ENABLE_EXPERIMENTAL_FEATURES"
          value = "true"
        },
        {
          name  = "CLICKHOUSE_URL"
          value = "http://${module.clickhouse_nlb.dns_name}:8123"
        },
        {
          name  = "CLICKHOUSE_MIGRATION_URL"
          value = "clickhouse://${module.clickhouse_nlb.dns_name}:9000"
        },
        {
          name  = "CLICKHOUSE_USER"
          value = "clickhouse"
        },
        {
          name  = "CLICKHOUSE_CLUSTER_ENABLED"
          value = "false"
        },
        {
          name  = "LANGFUSE_S3_EVENT_UPLOAD_BUCKET"
          value = module.langfuse_s3_bucket.s3_bucket_id
        },
        {
          name  = "LANGFUSE_S3_EVENT_UPLOAD_REGION"
          value = data.aws_region.current.region
        },
        {
          name  = "LANGFUSE_S3_EVENT_UPLOAD_PREFIX"
          value = "events/"
        },
        {
          name  = "LANGFUSE_S3_MEDIA_UPLOAD_BUCKET"
          value = module.langfuse_s3_bucket.s3_bucket_id
        },
        {
          name  = "LANGFUSE_S3_MEDIA_UPLOAD_REGION"
          value = data.aws_region.current.region
        },
        {
          name  = "LANGFUSE_S3_MEDIA_UPLOAD_PREFIX"
          value = "media/"
        },
        {
          name  = "LANGFUSE_S3_BATCH_EXPORT_ENABLED"
          value = "true"
        },
        {
          name  = "LANGFUSE_S3_BATCH_EXPORT_BUCKET"
          value = module.langfuse_s3_bucket.s3_bucket_id
        },
        {
          name  = "LANGFUSE_S3_BATCH_EXPORT_PREFIX"
          value = "exports/"
        },
        {
          name  = "LANGFUSE_S3_BATCH_EXPORT_REGION"
          value = data.aws_region.current.region
        },
        {
          name  = "REDIS_HOST"
          value = module.redis.replication_group_primary_endpoint_address
        },
        {
          name  = "REDIS_PORT"
          value = "6379"
        },
        {
          name  = "REDIS_TLS_ENABLED"
          value = "true"
        }
      ]

      secrets = concat([
        {
          name      = "DATABASE_URL"
          valueFrom = aws_secretsmanager_secret.database_url.arn
        },
        {
          name      = "SALT"
          valueFrom = aws_secretsmanager_secret.salt.arn
        },
        {
          name      = "NEXTAUTH_SECRET"
          valueFrom = aws_secretsmanager_secret.nextauth_secret.arn
        },
        {
          name      = "CLICKHOUSE_PASSWORD"
          valueFrom = aws_secretsmanager_secret.clickhouse_password.arn
        },
        {
          name      = "REDIS_AUTH"
          valueFrom = aws_secretsmanager_secret.redis_password.arn
        }
      ], var.use_encryption_key ? [
        {
          name      = "ENCRYPTION_KEY"
          valueFrom = aws_secretsmanager_secret.encryption_key[0].arn
        }
      ] : [])

      enable_cloudwatch_logging              = true
      cloudwatch_log_group_name             = "/ecs/${var.name}-web"
      cloudwatch_log_group_retention_in_days = 30
      # Force update to ensure port mappings are applied

      health_check = {
        command     = ["CMD-SHELL", "curl -f http://localhost:3000/api/public/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  }

  load_balancer = {
    service = {
      target_group_arn = module.alb.target_groups["langfuse"].arn
      container_name   = "langfuse-web"
      container_port   = 3000
    }
  }

  subnet_ids = var.private_subnet_ids
  security_group_ingress_rules = {
    alb_3000 = {
      description                  = "Service port"
      from_port                    = 3000
      to_port                      = 3000
      ip_protocol                  = "tcp"
      referenced_security_group_id = module.alb.security_group_id
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }


  tags = {
    Name = "${local.tag_name} Web Service"
  }
}