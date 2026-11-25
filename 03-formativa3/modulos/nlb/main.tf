resource "aws_lb" "nlb" {
  name               = "${var.nombre}-nlb"
  load_balancer_type = "network"
  subnets            = var.subredes
  tags               = merge(var.tags, { Name = "${var.nombre}-nlb" })
}

resource "aws_lb_target_group" "tg" {
  name     = "${var.nombre}-tg"
  port     = 80
  protocol = "TCP"
  vpc_id   = var.vpc_id
  tags     = merge(var.tags, { Name = "${var.nombre}-tg" })
}

resource "aws_lb_listener" "tcp" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }

  tags = merge(var.tags, { Name = "${var.nombre}-listener" })
}

# registra los servidores como targets con un ciclo
resource "aws_lb_target_group_attachment" "servidor" {
  for_each = var.instancias

  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = each.value
  port             = 80
}
