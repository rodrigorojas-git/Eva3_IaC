output "vpc_id" {
  value = aws_vpc.vpc_principal.id
}

output "subnet_ids" {
  value = aws_subnet.subred_publica[*].id

  depends_on = [aws_route_table_association.asociacion_publica]
}
