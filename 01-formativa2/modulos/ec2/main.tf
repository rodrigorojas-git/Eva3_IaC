locals {
  nombre = "${var.prefijo}-${var.nombre}"
}

resource "aws_security_group" "sg_ssh" {
  name   = "${local.nombre}-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "servidor" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  key_name               = "vockey"
  vpc_security_group_ids = [aws_security_group.sg_ssh.id]

  tags = {
    Name = local.nombre
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("labsuser.pem")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = ["echo Conectado a ${local.nombre}"]
  }
}
