output "nlb_dns" {
  value = module.nlb.dns_name
}

output "rds_endpoint" {
  value = module.rds.endpoint
}

output "bucket" {
  value = module.s3.bucket
}

output "ips_servidores" {
  value = module.ec2.ips_publicas
}
