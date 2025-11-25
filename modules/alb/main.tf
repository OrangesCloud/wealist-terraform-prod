# 1. ALB 본체
resource "aws_lb" "main" {
  name               = "${var.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.subnet_ids

  enable_deletion_protection = false

  tags = {
    Name = "${var.name_prefix}-alb"
  }
}

# --- Target Groups (4개) ---

# (1) User Service (8080)
resource "aws_lb_target_group" "user_tg" {
  name     = "${var.name_prefix}-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "instance"
  lambda_multi_value_headers_enabled = false
  proxy_protocol_v2 = false

  health_check {
    path                = "/api/users/actuator/health"
    healthy_threshold   = 3
    unhealthy_threshold = 3 # (정보대로 설정)
    timeout             = 5
    interval            = 20
    matcher             = "200"
    port                = "8080"
  }
  tags = {
    Name = "${var.name_prefix}user-tg"
  }
}

# (2) Board Service (8000)
resource "aws_lb_target_group" "board_tg" {
  name     = "${var.name_prefix}-board-tg"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "instance"

  health_check {
    path                = "/api/boards/health"
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 20
    matcher             = "200"
    port                = "traffic-port"
  }
  tags = {
    Name = "${var.name_prefix}-board-tg"
  }
}

# (3) Monitoring (3001)
resource "aws_lb_target_group" "monitoring_tg" {
  name     = "${var.name_prefix}-monitoring"
  port     = 3001
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "instance"

  health_check {
    path                = "/api/health"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 20
    matcher             = "200"
  }
  tags = {
    Name = "${var.name_prefix}-monitoring"
  }
}

# (4) Targets (9090)
# (삭제예정)
resource "aws_lb_target_group" "targets_tg" {
  name     = "${var.name_prefix}-targets"
  port     = 9090
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "instance"

  health_check {
    path                = "/targets"
    port                ="traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
  tags = {
    Name = "${var.name_prefix}-targets"
  }
}

# --- Listeners ---

# 1. HTTP (80) -> HTTPS Redirect
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# 2. HTTPS (443)
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-Res-2021-06"
  certificate_arn   = var.alb_cert_arn

  # 기본값: User TG
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.user_tg.arn
  }
}

# --- Listener Rules ---

# (HTTP) Priority 10: /api/board/* -> Board TG
resource "aws_lb_listener_rule" "http_board" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.board_tg.arn
  }

  condition {
    path_pattern {
      values = ["/api/board/*"]
    }
  }
}

# (HTTPS) Priority 1: /api/boards/api/ws/* -> Board TG
resource "aws_lb_listener_rule" "https_ws" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 1

  action {
    type             = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.board_tg.arn
      }
      stickiness {
        enabled = true
        duration = 86400
      }
    }
}

  condition {
    path_pattern {
      values = ["/api/boards/api/ws/*"]
    }
  }
}

# (HTTPS) Priority 2: /oauth2/authorization/* -> User TG
resource "aws_lb_listener_rule" "https_oauth" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 2

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.user_tg.arn
  }

  condition {
    path_pattern {
      values = ["/oauth2/authorization/*"]
    }
  }
}

# (HTTPS) Priority 3: /api/users/* -> User TG
resource "aws_lb_listener_rule" "https_users" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 3

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.user_tg.arn
  }

  condition {
    path_pattern {
      values = ["/api/users/*"]
    }
  }
}

# (HTTPS) Priority 4: /api/boards/* -> Board TG
resource "aws_lb_listener_rule" "https_boards" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 4

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.board_tg.arn
  }

  condition {
    path_pattern {
      values = ["/api/boards/*"]
    }
  }
}

# (HTTPS) Priority 5: /monitoring/* -> Monitoring TG
resource "aws_lb_listener_rule" "https_monitoring" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 5

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.monitoring_tg.arn
  }

  condition {
    path_pattern {
      values = ["/monitoring/*"]
    }
  }
}

# (HTTPS) Priority 6: /* -> Targets TG
resource "aws_lb_listener_rule" "https_targets" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 6

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.targets_tg.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}
