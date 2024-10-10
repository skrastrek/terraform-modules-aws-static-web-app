resource "aws_s3_bucket" "this" {
  bucket = "${var.name_prefix}-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.id}"

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }

  depends_on = [aws_s3_bucket_ownership_controls.this]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    bucket_key_enabled = true

    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
      kms_master_key_id = null
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id

  policy = data.aws_iam_policy_document.bucket.json
}

data "aws_iam_policy_document" "bucket" {
  statement {
    sid    = "ReadFromCloudFrontDistribution"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.this.arn]
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  ignore_public_acls      = true
  block_public_acls       = true
  restrict_public_buckets = true
  block_public_policy     = true
}

resource "aws_s3_bucket_intelligent_tiering_configuration" "all" {
  bucket = aws_s3_bucket.this.id
  name   = "all"

  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 180
  }
}
