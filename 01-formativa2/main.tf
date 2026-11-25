resource "random_string" "sufijo" {
  length  = 6
  upper   = false
  special = false
}

locals {
  prefijo = "${var.proyecto}-${random_string.sufijo.result}"
}

module "vpc" {
  source = "./modulos/vpc"

  prefijo       = local.prefijo
  vpc_cidr      = var.vpc_cidr
  cidr_subredes = var.cidr_subredes
}

module "ec2" {
  source = "./modulos/ec2"
  count  = length(var.cidr_subredes)

  prefijo   = local.prefijo
  nombre    = "web-${count.index}"
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.subnet_ids[count.index]
  ami_id    = var.ami_id
}

module "nlb" {
  source = "./modulos/nlb"
  count  = length(var.cidr_subredes)

  prefijo   = local.prefijo
  nombre    = "nlb-${count.index}"
  subnet_id = module.vpc.subnet_ids[count.index]
}

module "s3" {
  source = "./modulos/s3"

  prefijo = local.prefijo
  region  = var.region
  buckets = var.buckets
}
