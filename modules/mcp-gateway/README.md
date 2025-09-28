# MCP Gateway Registry Terraform Module

This Terraform module deploys the MCP Gateway Registry to AWS ECS Fargate with Aurora Serverless PostgreSQL and Keycloak authentication.

## Features

- **ECS Fargate**: Serverless container deployment
- **Aurora Serverless v2**: PostgreSQL database with auto-scaling
- **EFS**: Shared storage for MCP servers, models, and logs
- **Application Load Balancer**: With multiple listeners for different services
- **Service Connect**: For inter-service communication
- **Keycloak Authentication**: Integrated identity and access management
- **Secrets Manager**: Secure credential management
- **CloudWatch Logs**: Centralized logging

## Architecture

The module deploys two main services:

1. **Registry Service** - Main MCP Gateway Registry with Gradio UI (ports 80, 443, 7860)
2. **Auth Service** - Authentication service integrated with Keycloak (port 8888)

## Usage

```hcl
module "mcp_gateway" {
  source = "./modules/mcp-gateway"

  # Required variables
  name                    = "mcp-gateway-prod"
  vpc_id                  = "vpc-12345678"
  private_subnet_ids      = ["subnet-12345678", "subnet-87654321"]
  public_subnet_ids       = ["subnet-abcdef12", "subnet-21fedcba"]
  ecs_cluster_arn         = "arn:aws:ecs:us-west-2:123456789012:cluster/my-cluster"
  ecs_cluster_name        = "my-cluster"
  task_execution_role_arn = "arn:aws:iam::123456789012:role/ecsTaskExecutionRole"

  # Container images (build and push to ECR first)
  registry_image_uri    = "123456789012.dkr.ecr.us-west-2.amazonaws.com/mcp-gateway-registry:latest"
  auth_server_image_uri = "123456789012.dkr.ecr.us-west-2.amazonaws.com/mcp-gateway-auth:latest"

  # Keycloak configuration
  keycloak_url               = "https://keycloak.example.com"
  keycloak_external_url      = "https://keycloak.example.com"
  keycloak_realm             = "mcp-gateway"
  keycloak_client_id         = "mcp-gateway-web"
  keycloak_client_secret     = "your-client-secret"
  keycloak_m2m_client_id     = "mcp-gateway-m2m"
  keycloak_m2m_client_secret = "your-m2m-client-secret"

  # Optional domain configuration
  domain_name           = "mcp.example.com"
  create_route53_record = true
  route53_zone_id       = "Z1D633PJN98FT9"

  # Resource configuration
  cpu               = "1024"
  memory            = "2048"
  registry_replicas = 2
  auth_replicas     = 2

  # Database configuration
  postgres_min_capacity = 0.5
  postgres_max_capacity = 4.0

  # Networking
  alb_scheme         = "internet-facing"
  ingress_cidr_blocks = ["0.0.0.0/0"]

  # Tags
  environment     = "prod"
  additional_tags = {
    Owner       = "platform-team"
    CostCenter  = "engineering"
  }
}
```

## Prerequisites

1. **Existing Infrastructure**: This module requires existing VPC, ECS cluster, and task execution role
2. **Container Images**: Build and push container images to ECR using the provided build script
3. **Keycloak Setup**: Configure Keycloak realm and clients

## Building Container Images

Use the provided build script to create and push container images to ECR:

```bash
# Run from the root directory containing mcp-gateway-registry source
./build-and-push-ecr.sh

# Or just check prerequisites and create repositories
./build-and-push-ecr.sh --check-only
```

## Keycloak Configuration

The module is configured to use Keycloak as the only authentication provider. You need to:

1. Set up a Keycloak server (can be external or in the same cluster)
2. Create a realm (default: `mcp-gateway`)
3. Create a web client for the UI (default: `mcp-gateway-web`)
4. Create a machine-to-machine client for API access (default: `mcp-gateway-m2m`)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name prefix for MCP Gateway Registry resources | `string` | n/a | yes |
| vpc_id | ID of the VPC where resources will be created | `string` | n/a | yes |
| private_subnet_ids | List of private subnet IDs for ECS services | `list(string)` | n/a | yes |
| public_subnet_ids | List of public subnet IDs for ALB | `list(string)` | n/a | yes |
| ecs_cluster_arn | ARN of the existing ECS cluster | `string` | n/a | yes |
| ecs_cluster_name | Name of the existing ECS cluster | `string` | n/a | yes |
| task_execution_role_arn | ARN of the task execution IAM role | `string` | n/a | yes |
| registry_image_uri | ECR URI for registry service image | `string` | n/a | yes |
| auth_server_image_uri | ECR URI for auth server service image | `string` | n/a | yes |
| cpu | CPU allocation for containers | `string` | `"1024"` | no |
| memory | Memory allocation for containers | `string` | `"2048"` | no |
| registry_replicas | Number of replicas for registry service | `number` | `1` | no |
| auth_replicas | Number of replicas for auth service | `number` | `1` | no |
| keycloak_url | Keycloak server URL | `string` | `"http://keycloak:8080"` | no |
| keycloak_external_url | External Keycloak URL | `string` | `""` | no |
| keycloak_realm | Keycloak realm name | `string` | `"mcp-gateway"` | no |
| keycloak_client_id | Keycloak client ID for web application | `string` | `"mcp-gateway-web"` | no |
| keycloak_client_secret | Keycloak client secret for web application | `string` | `""` | no |
| keycloak_m2m_client_id | Keycloak machine-to-machine client ID | `string` | `"mcp-gateway-m2m"` | no |
| keycloak_m2m_client_secret | Keycloak machine-to-machine client secret | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| database_endpoint | PostgreSQL cluster endpoint |
| alb_dns_name | DNS name of the Application Load Balancer |
| service_urls | URLs for accessing the MCP Gateway Registry services |
| efs_id | EFS file system ID |
| secret_arns | ARNs of secrets stored in AWS Secrets Manager |
| admin_credentials | Admin credentials for initial setup |

## Security Considerations

- All secrets are stored in AWS Secrets Manager
- EFS storage is encrypted at rest and in transit
- PostgreSQL database is encrypted
- Security groups follow least privilege principles
- Container logs are sent to CloudWatch
- IAM roles use minimal required permissions

## Cost Optimization

- Aurora Serverless v2 automatically scales based on demand
- EFS uses provisioned throughput mode (configurable)
- ECS Fargate with FARGATE capacity provider
- CloudWatch logs with 30-day retention

## Monitoring and Logging

- CloudWatch Logs for all container output
- ECS Container Insights enabled
- Health checks configured for all services
- Performance Insights enabled for Aurora

## License

This module is provided as-is for demonstration purposes.