# ClickHouse Service
module "ecs_service_clickhouse" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 6.0"

  name         = "${var.name}-clickhouse"
  cluster_arn  = var.ecs_cluster_arn
  cpu          = var.clickhouse_cpu
  memory       = var.clickhouse_memory
  desired_count = var.clickhouse_replicas
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
  create_tasks_iam_role     = true
  tasks_iam_role_policies = {
    SecretsManagerAccess = aws_iam_policy.ecs_secrets_access.arn
  }

  # EFS volumes for ClickHouse data persistence
  volume = {
    clickhouse-data = {
      efs_volume_configuration = {
        file_system_id          = aws_efs_file_system.langfuse.id
        root_directory          = "/"
        access_point_id         = aws_efs_access_point.clickhouse[0].id
      }
    }
  }

  # Container definitions
  container_definitions = {
    clickhouse = {
      cpu       = tonumber(var.clickhouse_cpu)
      memory    = tonumber(var.clickhouse_memory)
      essential = true
      image     = "docker.io/clickhouse/clickhouse-server"
      readonlyRootFilesystem = false

      portMappings = [
        {
          name           = "clickhouse-http"
          containerPort = 8123
          protocol       = "tcp"
        },
        {
          name           = "clickhouse-native"
          containerPort = 9000
          protocol       = "tcp"
        }
      ]

      environment = [
        {
          name  = "CLICKHOUSE_DB"
          value = "default"
        },
        {
          name  = "CLICKHOUSE_USER"
          value = "clickhouse"
        },
      ]

      secrets = [
        {
          name      = "CLICKHOUSE_PASSWORD"
          valueFrom = aws_secretsmanager_secret.clickhouse_password.arn
        }
      ]

      mount_points = [
        {
          source_volume  = "clickhouse-data"
          container_path = "/var/lib/clickhouse"
          read_only      = false
        }
      ]

      enable_cloudwatch_logging              = true
      cloudwatch_log_group_name             = "/ecs/${var.name}-clickhouse"
      cloudwatch_log_group_retention_in_days = 30

      health_check = {
        command     = ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:8123/ping || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 10
        startPeriod = 60
      }
    }
  }

  subnet_ids = var.private_subnet_ids
  security_group_ingress_rules = {
    vpc_8123 = {
      type        = "ingress"
      description = "ClickHouse HTTP port"
      from_port   = 8123
      to_port     = 8123
      ip_protocol = "tcp"
      cidr_ipv4   = var.vpc_cidr
    }
    vpc_9000 = {
      type        = "ingress"
      description = "ClickHouse native port"
      from_port   = 9000
      to_port     = 9000
      ip_protocol = "tcp"
      cidr_ipv4   = var.vpc_cidr
    }
  }
  security_group_egress_rules = {
    all = {
      type        = "egress"
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  load_balancer = {
    clickhouse_http = {
      target_group_arn = module.clickhouse_nlb.target_groups["clickhouse_http"].arn
      container_name   = "clickhouse"
      container_port   = 8123
    }
    clickhouse_native = {
      target_group_arn = module.clickhouse_nlb.target_groups["clickhouse_native"].arn
      container_name   = "clickhouse"
      container_port   = 9000
    }
  }

  tags = {
    Name = "${local.tag_name} ClickHouse Service"
  }
}