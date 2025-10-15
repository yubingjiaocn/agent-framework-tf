data "aws_region" "current" {}
data "aws_partition" "current" {}

module "alb" {
  source = "terraform-aws-modules/alb/aws"
  version = "~> 10.0"

  name    = "${var.name}-alb"
  vpc_id  = var.vpc_id
  internal = var.alb_scheme == "internal" ? true : false
  subnets = var.alb_scheme == "internal" ? var.private_subnet_ids : var.public_subnet_ids
  enable_deletion_protection = false

  # Security Group
  security_group_ingress_rules = {
    http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = join(",", var.ingress_inbound_cidrs)
    },
    https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = join(",", var.ingress_inbound_cidrs)
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "langfuse"
      }
    }
  }

  target_groups = {
    langfuse = {
      name_prefix = "web-"
      port        = 3000
      protocol    = "HTTP"
      target_type = "ip"
      create_attachment = false
      health_check = {
        enabled             = true
        healthy_threshold   = 2
        unhealthy_threshold = 10
        timeout             = 5
        interval            = 30
        path                = "/api/public/health"
        matcher             = "200"
        port                = "traffic-port"
        protocol            = "HTTP"
      }
    }
  }
  tags = {
    Name = "${local.tag_name} ALB"
  }
}