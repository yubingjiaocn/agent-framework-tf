resource "random_bytes" "salt" {
  # Should be at least 256 bits (32 bytes): https://langfuse.com/self-hosting/configuration#core-infrastructure-settings ~> SALT
  length = 32
}

resource "random_bytes" "nextauth_secret" {
  # Should be at least 256 bits (32 bytes): https://langfuse.com/self-hosting/configuration#core-infrastructure-settings ~> NEXTAUTH_SECRET
  length = 32
}

resource "random_bytes" "encryption_key" {
  count = var.use_encryption_key ? 1 : 0
  # Must be exactly 256 bits (32 bytes): https://langfuse.com/self-hosting/configuration#core-infrastructure-settings ~> ENCRYPTION_KEY
  length = 32
}

# Secrets for environment variables (can be stored in Parameter Store or Secrets Manager in production)
locals {
  langfuse_env_vars = {
    NEXTAUTH_URL                      = "https://${module.alb.dns_name}"
    DATABASE_URL                      = "postgresql://langfuse:${random_password.postgres_password.result}@${module.aurora_postgresql.cluster_endpoint}:5432/langfuse"
    SALT                             = random_bytes.salt.base64
    NEXTAUTH_SECRET                  = random_bytes.nextauth_secret.base64
    ENCRYPTION_KEY                   = var.use_encryption_key ? random_bytes.encryption_key[0].hex : ""
    TELEMETRY_ENABLED                = "true"
    LANGFUSE_ENABLE_EXPERIMENTAL_FEATURES = "true"
    CLICKHOUSE_URL                   = "http://langfuse-clickhouse.${var.name}.local:8123"
    CLICKHOUSE_MIGRATION_URL         = "clickhouse://langfuse-clickhouse.${var.name}.local:9000"
    CLICKHOUSE_USER                  = "clickhouse"
    CLICKHOUSE_PASSWORD              = random_password.clickhouse_password.result
    LANGFUSE_S3_EVENT_UPLOAD_BUCKET  = module.langfuse_s3_bucket.s3_bucket_id
    LANGFUSE_S3_EVENT_UPLOAD_REGION  = data.aws_region.current.region
    LANGFUSE_S3_EVENT_UPLOAD_PREFIX  = "events/"
    LANGFUSE_S3_MEDIA_UPLOAD_BUCKET  = module.langfuse_s3_bucket.s3_bucket_id
    LANGFUSE_S3_MEDIA_UPLOAD_REGION  = data.aws_region.current.region
    LANGFUSE_S3_MEDIA_UPLOAD_PREFIX  = "media/"
    LANGFUSE_S3_BATCH_EXPORT_ENABLED = "true"
    LANGFUSE_S3_BATCH_EXPORT_BUCKET  = module.langfuse_s3_bucket.s3_bucket_id
    LANGFUSE_S3_BATCH_EXPORT_PREFIX  = "exports/"
    LANGFUSE_S3_BATCH_EXPORT_REGION  = data.aws_region.current.region
    REDIS_HOST                       = module.redis.replication_group_primary_endpoint_address
    REDIS_PORT                       = "6379"
    REDIS_AUTH                       = random_password.redis_password.result
    REDIS_TLS_ENABLED                = "true"
  }

  # Merge additional environment variables from user input
  all_env_vars = merge(
    local.langfuse_env_vars,
    { for env in var.additional_env : env.name => env.value if env.value != null }
  )
}