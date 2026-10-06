resource "aws_lb" "main" {
  name               = "${local.name_prefix}-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  drop_invalid_header_fields = true

  tags = { Name = "${local.name_prefix}-alb" }
}

resource "aws_lb_target_group" "api" {
  name        = "${local.name_prefix}-api-tg"
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "ip" # required for Fargate (awsvpc networking)
  vpc_id      = aws_vpc.main.id

  deregistration_delay = var.tg_deregistration_delay

  health_check {
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = var.tg_health_check_matcher
    interval            = var.tg_health_check_interval
    timeout             = var.tg_health_check_timeout
    healthy_threshold   = var.tg_healthy_threshold
    unhealthy_threshold = var.tg_unhealthy_threshold
  }

  tags = { Name = "${local.name_prefix}-api-tg" }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.https_port
  protocol          = "HTTPS"
  ssl_policy        = var.alb_ssl_policy
  certificate_arn   = aws_acm_certificate_validation.regional.certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Forbidden"
      status_code  = "403"
    }
  }
}

resource "aws_lb_listener_rule" "api_from_cloudfront" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }

  condition {
    path_pattern {
      values = [var.api_path_pattern]
    }
  }

  condition {
    http_header {
      http_header_name = var.origin_verify_header_name
      values           = [random_password.origin_verify.result]
    }
  }
}
