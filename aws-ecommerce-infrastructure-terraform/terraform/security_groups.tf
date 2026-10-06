resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "ALB: HTTPS from CloudFront only"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${local.name_prefix}-alb-sg" }
}

resource "aws_security_group" "ecs" {
  name        = "${local.name_prefix}-ecs-sg"
  description = "ECS tasks: traffic from ALB only"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${local.name_prefix}-ecs-sg" }
}

resource "aws_security_group" "rds" {
  name        = "${local.name_prefix}-rds-sg"
  description = "RDS PostgreSQL: from ECS only"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${local.name_prefix}-rds-sg" }
}

resource "aws_security_group" "redis" {
  name        = "${local.name_prefix}-redis-sg"
  description = "ElastiCache Redis: from ECS only"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${local.name_prefix}-redis-sg" }
}

resource "aws_security_group" "msk" {
  name        = "${local.name_prefix}-msk-sg"
  description = "MSK Kafka: from ECS only"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${local.name_prefix}-msk-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "alb_https_from_cloudfront" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from CloudFront origin-facing prefix list"
  prefix_list_id    = data.aws_ec2_managed_prefix_list.cloudfront.id
  ip_protocol       = "tcp"
  from_port         = var.https_port
  to_port           = var.https_port
}

resource "aws_vpc_security_group_egress_rule" "alb_to_ecs" {
  security_group_id            = aws_security_group.alb.id
  description                  = "To ECS tasks"
  referenced_security_group_id = aws_security_group.ecs.id
  ip_protocol                  = "tcp"
  from_port                    = var.container_port
  to_port                      = var.container_port
}

resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id            = aws_security_group.ecs.id
  description                  = "App port from ALB"
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = var.container_port
  to_port                      = var.container_port
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_rds" {
  security_group_id            = aws_security_group.ecs.id
  description                  = "To RDS"
  referenced_security_group_id = aws_security_group.rds.id
  ip_protocol                  = "tcp"
  from_port                    = var.db_port
  to_port                      = var.db_port
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_redis" {
  security_group_id            = aws_security_group.ecs.id
  description                  = "To ElastiCache"
  referenced_security_group_id = aws_security_group.redis.id
  ip_protocol                  = "tcp"
  from_port                    = var.redis_port
  to_port                      = var.redis_port
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_msk" {
  security_group_id            = aws_security_group.ecs.id
  description                  = "To MSK"
  referenced_security_group_id = aws_security_group.msk.id
  ip_protocol                  = "tcp"
  from_port                    = var.kafka_port
  to_port                      = var.kafka_port
}

resource "aws_vpc_security_group_egress_rule" "ecs_https_out" {
  security_group_id = aws_security_group.ecs.id
  description       = "HTTPS to AWS APIs / image registry via NAT"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = var.https_port
  to_port           = var.https_port
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_ecs" {
  security_group_id            = aws_security_group.rds.id
  description                  = "PostgreSQL from ECS"
  referenced_security_group_id = aws_security_group.ecs.id
  ip_protocol                  = "tcp"
  from_port                    = var.db_port
  to_port                      = var.db_port
}

resource "aws_vpc_security_group_ingress_rule" "redis_from_ecs" {
  security_group_id            = aws_security_group.redis.id
  description                  = "Redis from ECS"
  referenced_security_group_id = aws_security_group.ecs.id
  ip_protocol                  = "tcp"
  from_port                    = var.redis_port
  to_port                      = var.redis_port
}

resource "aws_vpc_security_group_ingress_rule" "msk_from_ecs" {
  security_group_id            = aws_security_group.msk.id
  description                  = "Kafka from ECS"
  referenced_security_group_id = aws_security_group.ecs.id
  ip_protocol                  = "tcp"
  from_port                    = var.kafka_port
  to_port                      = var.kafka_port
}
