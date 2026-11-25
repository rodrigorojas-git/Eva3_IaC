output "vpc_id" {
  value = aws_vpc.vpc_principal.id
}

output "subnet_ids" {
  value = aws_subnet.subred_publica[*].id

  # Quien use las subredes (EC2, NLB) espera a que el IGW y las rutas estén listos
  depends_on = [aws_route_table_association.asociacion_publica]
}
