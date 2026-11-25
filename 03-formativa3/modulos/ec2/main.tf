resource "aws_security_group" "servidores" {
  name   = "${var.nombre}-sg-servidores"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.nombre}-sg-servidores" })
}

# 3 servidores con un solo bloque
resource "aws_instance" "servidor" {
  for_each = var.servidores

  ami                    = var.ami_id
  instance_type          = each.value.tipo
  subnet_id              = var.subred_ids[each.value.subred]
  key_name               = var.llave
  vpc_security_group_ids = [aws_security_group.servidores.id]

  root_block_device {
    # condicional: en prod el disco se duplica
    volume_size = var.ambiente == "prod" ? each.value.disco * 2 : each.value.disco
  }

  # servidor web (para probar el NLB) + cliente mysql (para probar la RDS)
  user_data = <<-EOT
    #!/bin/bash
    dnf install -y httpd mariadb105
    echo "<h1>${each.key}</h1>" > /var/www/html/index.html
    systemctl enable --now httpd
  EOT

  tags = merge(var.tags, { Name = "${var.nombre}-${each.key}" })
}
