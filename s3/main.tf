resource "aws_s3_bucket" "newsletter_bucket" {
  bucket = "newsletter-bucket-${var.environment}"

  tags = {
    Environment = var.environment
  }
}

resource "aws_s3_bucket_object" "newsletter_object" {
  bucket = aws_s3_bucket.newsletter_bucket.id
  key    = "newsletter.txt"
  source = "../newsletter.txt"

  depends_on = [
    aws_s3_bucket.newsletter_bucket
  ]
}

resource "aws_s3_bucket_public_access_block" "newsletter_public_access_block" {
  bucket = aws_s3_bucket.newsletter_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  depends_on = [
    aws_s3_bucket.newsletter_bucket
  ]
}
