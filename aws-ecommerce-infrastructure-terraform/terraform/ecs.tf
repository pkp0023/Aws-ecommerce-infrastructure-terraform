resource "aws_ecs_cluster" "main" {
  name = "${local.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = var.container_insights
  }

  tags = { Name = "${local.name_prefix}-cluster" }
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "/ecs/${local.name_prefix}/${var.container_name}"
  retention_in_days = var.log_retention_days

  tags = { Name = "${local.name_prefix}-api-logs" }
}

resource "aws_cloudwatch_log_group" "worker" {
  name              = "/ecs/${local.name_prefix}/${var.worker_container_name}"
  retention_in_days = var.log_retention_days

  tags = { Name = "${local.name_prefix}-worker-logs" }
}

data "aws_iam_policy_document" "ecs_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_execution" {
  name               = "${local.name_prefix}-ecs-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_role_policy_attachment" "task_execution_managed" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "task_execution_secrets" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.db.arn]
  }
}

resource "aws_iam_role_policy" "task_execution_secrets" {
  name   = "read-db-secret"
  role   = aws_iam_role.task_execution.id
  policy = data.aws_iam_policy_document.task_execution_secrets.json
}

resource "aws_iam_role" "task" {
  name               = "${local.name_prefix}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

locals {
  # Environment shared by the API and the worker
  shared_environment = merge(
    {
      NODE_ENV      = var.environment
      REDIS_URL     = "redis://${aws_elasticache_cluster.redis.cache_nodes[0].address}:${var.redis_port}"
      KAFKA_BROKERS = aws_msk_cluster.main.bootstrap_brokers
    },
    var.container_environment
  )

  # DATABASE_URL is injected from Secrets Manager (never stored in plain text)
  shared_secrets = [{
    name      = "DATABASE_URL"
    valueFrom = "${aws_secretsmanager_secret.db.arn}:url::"
  }]

  # ---------------- API container ----------------
  api_container_base = {
    name      = var.container_name
    image     = var.container_image
    essential = true

    portMappings = [{
      containerPort = var.container_port
      protocol      = "tcp"
    }]

    environment = [for k, v in merge(
      local.shared_environment,
      { PORT = tostring(var.container_port) }
    ) : { name = k, value = v }]

    secrets = local.shared_secrets

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.api.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }

  api_container = merge(
    local.api_container_base,
    length(var.container_command) > 0 ? { command = var.container_command } : {}
  )

  # ---------------- Worker container (Kafka consumer) ----------------
  worker_container_base = {
    name      = var.worker_container_name
    image     = var.worker_container_image
    essential = true

    environment = [for k, v in local.shared_environment : { name = k, value = v }]

    secrets = local.shared_secrets

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.worker.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }

  worker_container = merge(
    local.worker_container_base,
    length(var.worker_container_command) > 0 ? { command = var.worker_container_command } : {}
  )
}

# ---------------------------------------------------------------------------
# API service (behind the ALB)
# ---------------------------------------------------------------------------
resource "aws_ecs_task_definition" "api" {
  family                   = "${local.name_prefix}-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([local.api_container])

  tags = { Name = "${local.name_prefix}-api-task" }
}

resource "aws_ecs_service" "api" {
  name            = "${local.name_prefix}-api"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = var.ecs_desired_count
  launch_type     = "FARGATE"

  health_check_grace_period_seconds = var.ecs_health_check_grace_period
  propagate_tags                    = "SERVICE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  tags = { Name = "${local.name_prefix}-api-service" }

  depends_on = [
    aws_lb_listener_rule.api_from_cloudfront,
    aws_secretsmanager_secret_version.db,
    aws_nat_gateway.main,
  ]
}

# ---------------------------------------------------------------------------
# Worker service (reads orders from Kafka, writes them to RDS).
# No load balancer: it only makes outbound calls to MSK / RDS / Redis, all of
# which the shared ECS security group already allows.
# ---------------------------------------------------------------------------
resource "aws_ecs_task_definition" "worker" {
  family                   = "${local.name_prefix}-worker"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.worker_cpu
  memory                   = var.worker_memory
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([local.worker_container])

  tags = { Name = "${local.name_prefix}-worker-task" }
}

resource "aws_ecs_service" "worker" {
  name            = "${local.name_prefix}-worker"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.worker.arn
  desired_count   = var.worker_desired_count
  launch_type     = "FARGATE"

  propagate_tags = "SERVICE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  tags = { Name = "${local.name_prefix}-worker-service" }

  depends_on = [
    aws_secretsmanager_secret_version.db,
    aws_nat_gateway.main,
  ]
}
