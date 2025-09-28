# Networking resources for MCP Gateway Registry

# Service Discovery Namespace
resource "aws_service_discovery_private_dns_namespace" "mcp" {
  name        = "${local.name_prefix}.local"
  description = "Service discovery namespace for MCP Gateway Registry"
  vpc         = var.vpc_id
  tags        = local.common_tags
}

# Application Load Balancer
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name               = "${local.name_prefix}-alb"
  load_balancer_type = "application"
  internal           = var.alb_scheme == "internal"

  vpc_id  = var.vpc_id
  subnets = var.alb_scheme == "internal" ? var.private_subnet_ids : var.public_subnet_ids

  # Security Groups
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = var.ingress_cidr_blocks[0]
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = var.ingress_cidr_blocks[0]
    }
    auth_port = {
      from_port   = 8888
      to_port     = 8888
      ip_protocol = "tcp"
      cidr_ipv4   = var.ingress_cidr_blocks[0]
    }
    gradio_port = {
      from_port   = 7860
      to_port     = 7860
      ip_protocol = "tcp"
      cidr_ipv4   = var.ingress_cidr_blocks[0]
    }
    keycloak_port = {
      from_port   = 8080
      to_port     = 8080
      ip_protocol = "tcp"
      cidr_ipv4   = var.ingress_cidr_blocks[0]
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
        target_group_key = "registry"
      }
    }
    auth = {
      port     = 8888
      protocol = "HTTP"
      forward = {
        target_group_key = "auth"
      }
    }
    gradio = {
      port     = 7860
      protocol = "HTTP"
      forward = {
        target_group_key = "gradio"
      }
    }
    keycloak = {
      port     = 8080
      protocol = "HTTP"
      forward = {
        target_group_key = "keycloak"
      }
    }
  }

  target_groups = {
    registry = {
      backend_protocol                  = "HTTP"
      backend_port                      = 80
      target_type                       = "ip"
      deregistration_delay              = 5
      load_balancing_cross_zone_enabled = true

      health_check = {
        enabled             = true
        healthy_threshold   = 2
        interval            = 30
        matcher             = "200"
        path                = "/health"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }

      create_attachment = false
    }
    auth = {
      backend_protocol                  = "HTTP"
      backend_port                      = 8888
      target_type                       = "ip"
      deregistration_delay              = 5
      load_balancing_cross_zone_enabled = true

      health_check = {
        enabled             = true
        healthy_threshold   = 2
        interval            = 30
        matcher             = "200"
        path                = "/health"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }

      create_attachment = false
    }
    gradio = {
      backend_protocol                  = "HTTP"
      backend_port                      = 7860
      target_type                       = "ip"
      deregistration_delay              = 5
      load_balancing_cross_zone_enabled = true

      health_check = {
        enabled             = true
        healthy_threshold   = 2
        interval            = 30
        matcher             = "200"
        path                = "/health"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }

      create_attachment = false
    }
    keycloak = {
      backend_protocol                  = "HTTP"
      backend_port                      = 8080
      target_type                       = "ip"
      deregistration_delay              = 5
      load_balancing_cross_zone_enabled = true

      health_check = {
        enabled             = true
        healthy_threshold   = 2
        interval            = 60
        matcher             = "200"
        path                = "/health/ready"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 10
        unhealthy_threshold = 3
      }

      create_attachment = false
    }
  }

  tags = local.common_tags
}
