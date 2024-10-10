output "domain_name" {
  value = aws_route53_record.alias_cloudfront.name
}

output "s3_bucket_read_iam_policy_arn" {
  value = aws_iam_policy.s3_bucket_read.arn
}

output "s3_bucket_write_iam_policy_arn" {
  value = aws_iam_policy.s3_bucket_write.arn
}
