output "bucket_names" {
  value = [for b in null_resource.bucket_privado : b.triggers.bucket]
}
