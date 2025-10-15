
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.dns_name
}

output "application_url" {
  description = "URL to access the Langfuse application"
  value       = "https://${module.alb.dns_name}"
}

output "bucket_name" {
  description = "Name of the S3 bucket for Langfuse"
  value       = module.langfuse_s3_bucket.s3_bucket_id
}

output "bucket_id" {
  description = "ID of the S3 bucket for Langfuse"
  value       = module.langfuse_s3_bucket.s3_bucket_id
}

output "rds_cluster_endpoint" {
  description = "RDS cluster endpoint"
  value       = module.aurora_postgresql.cluster_endpoint
  sensitive   = true
}

output "redis_endpoint" {
  description = "Redis cluster endpoint"
  value       = module.redis.replication_group_primary_endpoint_address
  sensitive   = true
}