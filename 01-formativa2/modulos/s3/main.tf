locals {
  nombre = "${var.prefijo}-s3"
}

resource "null_resource" "bucket_privado" {
  for_each = var.buckets

  triggers = {
    bucket = "${local.nombre}-${each.key}"
    region = var.region
  }

  provisioner "local-exec" {
    command = "aws s3api create-bucket --bucket ${self.triggers.bucket} --region ${self.triggers.region} && aws s3api put-public-access-block --bucket ${self.triggers.bucket} --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "aws s3 rb s3://${self.triggers.bucket} --force"
  }
}
