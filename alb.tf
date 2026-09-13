resource "aws_lb_target_group" "service" {
  for_each = local.services

  name        = "${local.name_prefix}-${each.key}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = each.value.health_check
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name    = "${local.name_prefix}-${each.key}-tg"
    Service = each.key
  }
}


resource "aws_lb" "main" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb.id
  ]

  subnets = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id
  ]

  tags = {
    Name = "${local.name_prefix}-alb"
  }
}


resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"

    forward {
      target_group {
        arn = aws_lb_target_group.service["user"].arn
      }
    }
  }
}


resource "aws_lb_listener_rule" "payment" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type = "forward"

    forward {
      target_group {
        arn = aws_lb_target_group.service["payment"].arn
      }
    }
  }

  condition {
    path_pattern {
      values = ["/payments*"]
    }
  }
}


resource "aws_lb_listener_rule" "notification" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 20

  action {
    type = "forward"

    forward {
      target_group {
        arn = aws_lb_target_group.service["notification"].arn
      }
    }
  }

  condition {
    path_pattern {
      values = ["/notifications*"]
    }
  }
}
