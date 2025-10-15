# S3 access policy for ECS tasks
resource "aws_iam_policy" "ecs_s3_access" {
  name = "${var.name}-ecs-s3-access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          module.langfuse_s3_bucket.s3_bucket_arn,
          "${module.langfuse_s3_bucket.s3_bucket_arn}/*"
        ]
      }
    ]
  })

  tags = {
    Name = "${local.tag_name} ECS S3 Access"
  }
}