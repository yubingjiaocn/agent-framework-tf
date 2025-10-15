# Random password for ClickHouse
# Using a alphanumeric password to avoid issues with special characters on bash entrypoint
resource "random_password" "clickhouse_password" {
  length      = 64
  special     = false
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
}

# EFS Access Points for Clickhouse instances
resource "aws_efs_access_point" "clickhouse" {
  count          = var.clickhouse_instance_count
  file_system_id = aws_efs_file_system.langfuse.id

  root_directory {
    path = "/clickhouse/${count.index}"
    creation_info {
      owner_gid   = 1001
      owner_uid   = 1001
      permissions = "0755"
    }
  }

  posix_user {
    gid = 1001
    uid = 1001
  }

  tags = {
    Name = "${local.tag_name} Clickhouse"
  }
}

# EFS Access Points for Zookeeper instances
resource "aws_efs_access_point" "zookeeper" {
  count          = var.clickhouse_instance_count
  file_system_id = aws_efs_file_system.langfuse.id

  root_directory {
    path = "/zookeeper/${count.index}"
    creation_info {
      owner_gid   = 1001
      owner_uid   = 1001
      permissions = "0755"
    }
  }

  posix_user {
    gid = 1001
    uid = 1001
  }

  tags = {
    Name = "${local.tag_name} Zookeper"
  }
}

# EFS file system for ClickHouse data persistence
resource "aws_efs_file_system" "clickhouse" {
  creation_token  = "${var.name}-clickhouse-efs"
  encrypted       = true
  throughput_mode = "elastic"

  tags = {
    Name = "${local.tag_name} ClickHouse"
  }
}

# Mount targets for ClickHouse EFS in each private subnet
resource "aws_efs_mount_target" "clickhouse" {
  count           = length(var.private_subnet_ids)
  file_system_id  = aws_efs_file_system.clickhouse.id
  subnet_id       = var.private_subnet_ids[count.index]
  security_groups = [aws_security_group.efs.id]
}

# Note: ClickHouse data persistence is now handled by ECS service using EFS volumes
# See ecs-clickhouse-service.tf for the ECS-based ClickHouse implementation