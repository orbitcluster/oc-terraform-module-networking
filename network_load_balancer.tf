# Network Load Balancer (optional)
resource "aws_lb" "network" {
  count = var.enable_network_load_balancer ? 1 : 0

  name               = "${var.vpc_name}-nlb"
  load_balancer_type = "network"
  internal           = false

  subnets = length(var.nlb_subnet_ids) > 0 ? var.nlb_subnet_ids : module.vpc.public_subnets

  enable_deletion_protection       = var.nlb_deletion_protection
  enable_cross_zone_load_balancing = true

  tags = merge(
    local.common_tags,
    {
      Name = "${var.vpc_name}-nlb"
    }
  )
}

# NLB Target Group
resource "aws_lb_target_group" "network" {
  count = var.enable_network_load_balancer ? 1 : 0

  name     = "${var.vpc_name}-nlb-tg"
  port     = 443
  protocol = "TCP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    enabled             = true
    protocol            = "TCP"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
  }

  deregistration_delay = 30

  tags = merge(
    local.common_tags,
    {
      Name = "${var.vpc_name}-nlb-tg"
    }
  )
}

# NLB Listener
resource "aws_lb_listener" "network" {
  count = var.enable_network_load_balancer ? 1 : 0

  load_balancer_arn = aws_lb.network[0].arn
  port              = 443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.network[0].arn
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.vpc_name}-nlb-listener"
    }
  )
}
