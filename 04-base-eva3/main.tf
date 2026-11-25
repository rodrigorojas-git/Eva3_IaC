resource "random_string" "sufijo" {
  length  = 10
  upper   = false
  special = false
}

# FUNCIONES usadas: format (nombres), merge (tags), lookup (clase RDS),
#                   length y keys (outputs)
#
# CONDICIONALES (ambiente = "prod"):
# - discos x2       → modulos/ec2/main.tf (local.factor)
# - RDS Multi-AZ    → modulos/rds/main.tf
# - versionado S3   → modulos/s3/main.tf (local.estado)
#
# LOCALS por módulo:
# - raíz: nombre, bucket, tags  (este archivo)
# - vpc : nombre_vpc, publicas  (modulos/vpc/main.tf)
# - ec2 : nombre_sg, factor     (modulos/ec2/main.tf)
# - nlb : nombre_nlb, nombre_tg (modulos/nlb/main.tf)
# - rds : nombre_db, motor      (modulos/rds/main.tf)
# - s3  : nombre_bucket, estado (modulos/s3/main.tf)
locals {
  # format(): arma nombres a partir de variables
  nombre = format("%s-%s-%s", var.proyecto, var.aplicacion, var.ambiente)
  bucket = format("%s-%s", local.nombre, random_string.sufijo.result)

  # tags comunes (cada módulo los aplica con merge)
  tags = {
    Proyecto    = var.proyecto
    Ambiente    = var.ambiente
    Responsable = var.responsable
  }
}

module "vpc" {
  source = "./modulos/vpc"

  nombre   = local.nombre
  vpc_cidr = var.vpc_cidr
  subredes = var.subredes
  tags     = local.tags
}

module "ec2" {
  source = "./modulos/ec2"

  nombre     = local.nombre
  vpc_id     = module.vpc.vpc_id
  subred_ids = module.vpc.subred_ids
  servidores = var.servidores
  ami_id     = var.ami_id
  llave      = var.llave
  ambiente   = var.ambiente
  tags       = local.tags
}

module "nlb" {
  source = "./modulos/nlb"

  nombre     = local.nombre
  vpc_id     = module.vpc.vpc_id
  subredes   = module.vpc.subredes_publicas
  instancias = module.ec2.instancia_ids
  tags       = local.tags
}

module "rds" {
  source = "./modulos/rds"

  nombre        = local.nombre
  vpc_id        = module.vpc.vpc_id
  subredes      = module.vpc.subredes_privadas
  sg_servidores = module.ec2.sg_id
  clase         = lookup(var.db_clase, var.ambiente, "db.t3.micro")
  usuario       = var.db_usuario
  password      = var.db_password
  ambiente      = var.ambiente
  tags          = local.tags
}

module "s3" {
  source = "./modulos/s3"

  bucket   = local.bucket
  ambiente = var.ambiente
  tags     = local.tags
}
