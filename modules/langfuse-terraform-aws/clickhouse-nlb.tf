# Internal NLB for ClickHouse service communication
module "clickhouse_nlb" {
  source = "terraform-aws-modules/alb/aws"
  version = "~> 10.0"

  name    = "${var.name}-clickhouse-nlb"
  load_balancer_type = "network"
  vpc_id  = var.vpc_id
  subnets = var.private_subnet_ids
  enable_deletion_protection = false
  enable_cross_zone_load_balancing = true

  # Internal NLB for private communication
  internal = true

  # Security Group
  security_group_ingress_rules = {
    clickhouse_http = {
      from_port   = 8123
      to_port     = 8123
      ip_protocol = "tcp"
      cidr_ipv4   = var.vpc_cidr
    },
    clickhouse_native = {
      from_port   = 9000
      to_port     = 9000
      ip_protocol = "tcp"
      cidr_ipv4   = var.vpc_cidr
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  listeners = {
    clickhouse_http = {
      port     = 8123
      protocol = "TCP"
      forward = {
        target_group_key = "clickhouse_http"
      }
    },
    clickhouse_native = {
      port     = 9000
      protocol = "TCP"
      forward = {
        target_group_key = "clickhouse_native"
      }
    }
  }

  target_groups = {
    clickhouse_http = {
      name_prefix = "ch-h-"
      port        = 8123
      protocol    = "TCP"
      target_type = "ip"
      create_attachment = false
    }
    clickhouse_native = {
      name_prefix = "ch-n-"
      port        = 9000
      protocol    = "TCP"
      target_type = "ip"
      create_attachment = false
    }
  }

  tags = {
    Name = "${local.tag_name} ClickHouse Internal NLB"
  }
}