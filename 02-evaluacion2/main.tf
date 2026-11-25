resource "random_string" "sufijo" {
  length  = 10
  upper   = false
  special = false
}

locals {
  prefijo = "${var.proyecto}-${random_string.sufijo.result}"
  nombre = "${var.prefijo}-${var.nombre}"
}

module "vpc" {
  source = "./modulos/vpc"

  prefijo       = local.prefijo
  vpc_cidr      = var.vpc_cidr
  cidr_subredes = var.cidr_subredes
  
}


module "ec2" {
  source = "./modulos/ec2"
  count  = var.cantidad_ec2

  prefijo       = local.prefijo
  nombre        = "ec2-${count.index}"
  vpc_id        = module.vpc.vpc_id
  subnet_id     = module.vpc.subnet_ids[2]
  ami_id        = var.ami_id
  instance_type = var.instance_type
}


module "nlb" {
  source = "./modulos/nlb"
  count  = var.cantidad_nlb

  prefijo   = local.prefijo
  nombre    = "nlb-${count.index}"
  subnet_id = module.vpc.subnet_ids[1]
}

module "s3" {
  source = "./modulos/s3"

  prefijo = local.prefijo
  region  = var.region
  buckets = var.buckets
}

module "rds" {
  source = "./modulos/rds"
  nombre = "mydb"

  prefijo        = local.prefijo
  vpc_id         = module.vpc.vpc_id
  vpc_cidr       = var.vpc_cidr
  subnet_ids     = module.vpc.subnet_ids
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class
  usuario        = var.db_usuario
  password       = var.db_password

}
