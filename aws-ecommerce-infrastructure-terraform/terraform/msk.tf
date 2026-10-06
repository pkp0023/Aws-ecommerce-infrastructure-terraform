resource "aws_cloudwatch_log_group" "msk" {
  name              = "/aws/msk/${local.name_prefix}"
  retention_in_days = var.log_retention_days

  tags = { Name = "${local.name_prefix}-msk-logs" }
}

resource "aws_msk_cluster" "main" {
  cluster_name           = "${local.name_prefix}-kafka"
  kafka_version          = var.kafka_version
  number_of_broker_nodes = var.kafka_broker_count
  enhanced_monitoring    = "DEFAULT"

  broker_node_group_info {
    instance_type   = var.kafka_instance_type
    client_subnets  = aws_subnet.private[*].id # 1 broker per AZ across the 2 private subnets
    security_groups = [aws_security_group.msk.id]

    storage_info {
      ebs_storage_info {
        volume_size = var.kafka_ebs_volume_size
      }
    }
  }

  encryption_info {
    encryption_in_transit {
      client_broker = var.kafka_client_broker_encryption
      in_cluster    = true
    }
  }

  client_authentication {
    unauthenticated = true # access is restricted by the MSK security group (ECS only)
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.msk.name
      }
    }
  }

  tags = { Name = "${local.name_prefix}-kafka" }
}
