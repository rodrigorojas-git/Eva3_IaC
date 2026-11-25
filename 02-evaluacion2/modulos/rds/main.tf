locals {
  nombre = "${var.prefijo}-${var.nombre}"
}

resource "aws_db_subnet_group" "grupo_subredes" {
  name       = "${local.nombre}-subnets"
  subnet_ids = var.subnet_ids

}

resource "aws_security_group" "sg_rds" {
  name   = "${local.nombre}-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_db_instance" "postgres" {

  identifier             = local.nombre
  engine                 = "postgres"
  engine_version         = var.engine_version
  instance_class         = var.instance_class
  allocated_storage      = 20
  username               = var.usuario
  password               = var.password
  db_subnet_group_name   = aws_db_subnet_group.grupo_subredes.name
  vpc_security_group_ids = [aws_security_group.sg_rds.id]
  publicly_accessible    = false
  skip_final_snapshot    = true

}
