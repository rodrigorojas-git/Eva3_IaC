output "instancia_ids" {
  value = { for k, s in aws_instance.servidor : k => s.id }
}

output "ips_publicas" {
  value = { for k, s in aws_instance.servidor : k => s.public_ip }
}

output "sg_id" {
  value = aws_security_group.servidores.id
}
