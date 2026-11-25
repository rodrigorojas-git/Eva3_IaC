data "aws_availability_zones" "disponibles" {
  state = "available"
}

locals {
  nombre = "${var.prefijo}-vpc"
}

resource "aws_vpc" "vpc_principal" {
  cidr_block = var.vpc_cidr

   tags = {
    Name = local.nombre
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_principal.id
  
}

resource "aws_subnet" "subred_publica" {
  count = length(var.cidr_subredes)

  vpc_id                  = aws_vpc.vpc_principal.id
  cidr_block              = var.cidr_subredes[count.index]
  availability_zone       = data.aws_availability_zones.disponibles.names[count.index]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${local.nombre}-subred-${count.index + 1}"
  }
}

resource "aws_route_table" "tabla_publica" {
  vpc_id = aws_vpc.vpc_principal.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

}

resource "aws_route_table_association" "asociacion_publica" {
  count = length(var.cidr_subredes)

  subnet_id      = aws_subnet.subred_publica[count.index].id
  route_table_id = aws_route_table.tabla_publica.id
}
