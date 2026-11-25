locals {
  nombre_vpc = "${var.nombre}-vpc"
  publicas   = { for k, s in var.subredes : k => s if s.publica }
}

resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr
  tags       = merge(var.tags, { Name = local.nombre_vpc })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(var.tags, { Name = "${var.nombre}-igw" })
}

# 4 subredes con un solo bloque
resource "aws_subnet" "subred" {
  for_each = var.subredes

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = each.value.publica
  tags                    = merge(var.tags, { Name = "${var.nombre}-${each.key}" })
}

resource "aws_route_table" "publica" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(var.tags, { Name = "${var.nombre}-rt-publica" })
}

# solo las subredes públicas salen a internet
resource "aws_route_table_association" "publica" {
  for_each = local.publicas

  subnet_id      = aws_subnet.subred[each.key].id
  route_table_id = aws_route_table.publica.id
}
