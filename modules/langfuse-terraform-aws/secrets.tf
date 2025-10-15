# AWS Secrets Manager for Langfuse secrets

# PostgreSQL password secret
resource "aws_secretsmanager_secret" "postgres_password" {
  name_prefix             = "${var.name}-postgres-password"
  description             = "PostgreSQL password for Langfuse"

  tags = {
    Name = "${local.tag_name} PostgreSQL Password"
    stack = "${local.tag_name}"
  }
}

resource "aws_secretsmanager_secret_version" "postgres_password" {
  secret_id     = aws_secretsmanager_secret.postgres_password.id
  secret_string = random_password.postgres_password.result
}

# Redis password secret
resource "aws_secretsmanager_secret" "redis_password" {
  name_prefix             = "${var.name}-redis-password"
  description             = "Redis password for Langfuse"

  tags = {
    Name = "${local.tag_name} Redis Password"
    stack = "${local.tag_name}"
  }
}

resource "aws_secretsmanager_secret_version" "redis_password" {
  secret_id     = aws_secretsmanager_secret.redis_password.id
  secret_string = random_password.redis_password.result
}

# ClickHouse password secret
resource "aws_secretsmanager_secret" "clickhouse_password" {
  name_prefix             = "${var.name}-clickhouse-password"
  description             = "ClickHouse password for Langfuse"

  tags = {
    Name = "${local.tag_name} ClickHouse Password"
    stack = "${local.tag_name}"
  }
}

resource "aws_secretsmanager_secret_version" "clickhouse_password" {
  secret_id     = aws_secretsmanager_secret.clickhouse_password.id
  secret_string = random_password.clickhouse_password.result
}

# Salt secret
resource "aws_secretsmanager_secret" "salt" {
  name_prefix             = "${var.name}-salt"
  description             = "Salt for Langfuse"

  tags = {
    Name = "${local.tag_name} Salt"
    stack = "${local.tag_name}"
  }
}

resource "aws_secretsmanager_secret_version" "salt" {
  secret_id     = aws_secretsmanager_secret.salt.id
  secret_string = random_bytes.salt.base64
}

# NextAuth secret
resource "aws_secretsmanager_secret" "nextauth_secret" {
  name_prefix             = "${var.name}-nextauth-secret"
  description             = "NextAuth secret for Langfuse"

  tags = {
    Name = "${local.tag_name} NextAuth Secret"
    stack = "${local.tag_name}"
  }
}

resource "aws_secretsmanager_secret_version" "nextauth_secret" {
  secret_id     = aws_secretsmanager_secret.nextauth_secret.id
  secret_string = random_bytes.nextauth_secret.base64
}

# Encryption key secret (conditional)
resource "aws_secretsmanager_secret" "encryption_key" {
  count                   = var.use_encryption_key ? 1 : 0
  name_prefix             = "${var.name}-encryption-key"
  description             = "Encryption key for Langfuse"

  tags = {
    Name = "${local.tag_name} Encryption Key"
    stack = "${local.tag_name}"
  }
}

resource "aws_secretsmanager_secret_version" "encryption_key" {
  count         = var.use_encryption_key ? 1 : 0
  secret_id     = aws_secretsmanager_secret.encryption_key[0].id
  secret_string = random_bytes.encryption_key[0].hex
}

# Combined database URL secret
resource "aws_secretsmanager_secret" "database_url" {
  name_prefix            = "${var.name}-database-url"
  description             = "Database URL for Langfuse"

  tags = {
    Name = "${local.tag_name} Database URL"
    stack = "${local.tag_name}"
  }
}

resource "aws_secretsmanager_secret_version" "database_url" {
  secret_id     = aws_secretsmanager_secret.database_url.id
  secret_string = "postgresql://langfuse:${random_password.postgres_password.result}@${module.aurora_postgresql.cluster_endpoint}:5432/langfuse"
}

# IAM policy for ECS tasks to access secrets
resource "aws_iam_policy" "ecs_secrets_access" {
  name        = "${var.name}-ecs-secrets-access"
  description = "Policy for ECS tasks to access Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Resource = ["*"]
      Condition = {
        StringEquals = {
          "secretsmanager:ResourceTag/stack": local.tag_name
        }
      }
    }])
  })

  tags = {
    Name = "${local.tag_name} ECS Secrets Access"
  }
}