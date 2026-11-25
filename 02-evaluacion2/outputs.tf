output "vpc_id" {
  value = module.vpc.vpc_id
}

output "subnet_ids" {
  value = module.vpc.subnet_ids
}

output "ec2_ips_publicas" {
  value = module.ec2[*].public_ip
}

output "nlb_dns" {
  value = module.nlb[*].dns_name
}

output "buckets" {
  value = module.s3.bucket_names
}

output "rds_endpoint" {
  value = module.rds.endpoint
}
