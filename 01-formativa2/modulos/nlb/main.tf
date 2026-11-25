locals {
  nombre = "${var.prefijo}-${var.nombre}"
}

resource "aws_lb" "nlb" {
  name               = local.nombre
  load_balancer_type = "network"
  subnets            = [var.subnet_id]
}
