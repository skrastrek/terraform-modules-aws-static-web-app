resource "aws_iam_policy" "s3_bucket_read" {
  name   = "${var.name_prefix}-s3-bucket-read"
  policy = module.s3_bucket_read.json
}

module "s3_bucket_read" {
  source = "github.com/skrastrek/terraform-modules-aws-iam//policy-document/s3-bucket-read?ref=v0.0.1"

  s3_bucket_arn = aws_s3_bucket.this.arn
}

resource "aws_iam_policy" "s3_bucket_write" {
  name   = "${var.name_prefix}-s3-bucket-write"
  policy = module.s3_bucket_write.json
}

module "s3_bucket_write" {
  source = "github.com/skrastrek/terraform-modules-aws-iam//policy-document/s3-bucket-write?ref=v0.0.1"

  s3_bucket_arn = aws_s3_bucket.this.arn
}
