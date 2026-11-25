locals {
  nombre_db = "${var.nombre}-mysql"
  motor     = "mysql"
}

resource "aws_db_subnet_group" "rds" {
  name       = "${var.nombre}-rds-subnets"
  subnet_ids = var.subredes
  tags       = merge(var.tags, { Name = "${var.nombre}-rds-subnets" })
}

# solo acepta conexiones desde el SG de los servidores
resource "aws_security_group" "rds" {
  name   = "${var.nombre}-sg-rds"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.sg_servidores]
  }

  tags = merge(var.tags, { Name = "${var.nombre}-sg-rds" })
}

resource "aws_db_instance" "mysql" {
  identifier             = local.nombre_db
  engine                 = local.motor
  instance_class         = var.clase
  allocated_storage      = 20
  username               = var.usuario
  password               = var.password
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  multi_az               = var.ambiente == "prod" # condicional
  skip_final_snapshot    = true
  tags                   = merge(var.tags, { Name = "${var.nombre}-mysql" })
}
