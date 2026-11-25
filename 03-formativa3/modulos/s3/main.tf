resource "aws_s3_bucket" "bucket" {
  bucket        = var.bucket
  force_destroy = true # permite el destroy aunque tenga archivos
  tags          = merge(var.tags, { Name = var.bucket })
}

resource "aws_s3_bucket_versioning" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  versioning_configuration {
    status = var.ambiente == "prod" ? "Enabled" : "Suspended" # condicional
  }
}
