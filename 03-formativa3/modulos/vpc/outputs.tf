output "vpc_id" {
  value = aws_vpc.vpc.id
}

# mapa nombre => id (lo usa EC2 para ubicar cada servidor)
output "subred_ids" {
  value = { for k, s in aws_subnet.subred : k => s.id }

  depends_on = [aws_route_table_association.publica]
}

output "subredes_publicas" {
  value = [for k, s in var.subredes : aws_subnet.subred[k].id if s.publica]

  depends_on = [aws_route_table_association.publica]
}

output "subredes_privadas" {
  value = [for k, s in var.subredes : aws_subnet.subred[k].id if !s.publica]
}
