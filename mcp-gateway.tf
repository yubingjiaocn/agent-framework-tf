# MCP Gateway Module
# Uses pre-built images from Docker Hub (mcpgateway organization)
module "mcp_gateway" {
  count  = var.deploy_mcp_gateway ? 1 : 0
  source = "./modules/mcp-gateway"

  # Required: Basic configuration
  name = "${var.name}-mcp-gateway"

  # Required: Network configuration
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets
  public_subnet_ids  = module.vpc.public_subnets

  # Required: ECS configuration
  ecs_cluster_arn         = module.ecs_cluster.arn
  ecs_cluster_name        = module.ecs_cluster.name
  task_execution_role_arn = module.ecs_cluster.task_exec_iam_role_arn

  # Optional: Container images (defaults to pre-built images from mcpgateway Docker Hub)
  # registry_image_uri    = "mcpgateway/registry:latest"
  # auth_server_image_uri = "mcpgateway/auth-server:latest"
  # keycloak_image_uri    = "mcpgateway/keycloak:latest"

  # Optional: Keycloak configuration
  keycloak_ingress_cidr = var.vpc_cidr
}
