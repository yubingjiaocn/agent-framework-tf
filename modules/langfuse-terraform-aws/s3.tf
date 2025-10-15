module "langfuse_s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.7"
  bucket_prefix = var.name
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  versioning = {
    enabled = false
  }

  tags = {
    Name    = "${var.name}"
    Domain  = var.domain
    Service = "langfuse"
  }
}

resource "aws_s3_bucket_public_access_block" "langfuse" {
  bucket = module.langfuse_s3_bucket.s3_bucket_id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Add lifecycle rules for cost optimization
resource "aws_s3_bucket_lifecycle_configuration" "langfuse" {
  bucket = module.langfuse_s3_bucket.s3_bucket_id

  # https://aws.amazon.com/s3/storage-classes/
  # Transition to "STANDARD Infrequent Access" after 90 days, and
  # to "GLACIER Instant Retrieval" after 180 days
  rule {
    id     = "langfuse_lifecycle"
    status = "Enabled"

    filter {
      prefix = "" # Empty prefix matches all objects
    }

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 180
      storage_class = "GLACIER_IR"
    }
  }
}

# Create ECS task role for Langfuse service
resource "aws_iam_role" "langfuse_task_role" {
  name = "${var.name}-ecs-task-role"
  path = "/ecs/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${local.tag_name} ECS Task Role"
  }
}

# S3 access policy for the ECS task role
resource "aws_iam_role_policy" "langfuse_s3_access" {
  name = "s3-access"
  role = aws_iam_role.langfuse_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          module.langfuse_s3_bucket.s3_bucket_arn,
          "${module.langfuse_s3_bucket.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}
