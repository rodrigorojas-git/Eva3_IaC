output "instance_id" {
  value = aws_instance.servidor.id
}

output "public_ip" {
  value = aws_instance.servidor.public_ip
}
