# Configure the provider.
terraform {
  required_version = ">= 1.4.0"
  required_providers {
    aws = ">= 3.46.0"
  }
}

# Define the provider.
provider "aws" {
  region = var.aws_primary_region
}

# Define the S3 bucket for storing the newsletter content.
resource "aws_s3_bucket" "newsletter_bucket" {
  bucket = var.s3_bucket_name

  # Enable versioning for the bucket.
  versioning {
    enabled = true
  }

  # Configure the bucket to be public.
  acl = "public-read"

  # Define tags for the bucket.
  tags = {
    Name = "food-explorer-newsletter-bucket"
  }
}

# Define the DynamoDB table for storing subscriber information.
resource "aws_dynamodb_table" "subscribers" {
  name           = var.subscribers_table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "email"
  stream_enabled = true

  attribute {
    name = "email"
    type = "S"
  }

  attribute {
    name = "region"
    type = "S"
  }

  attribute {
    name = "cuisine"
    type = "S"
  }
}

# Define the IAM policy for the Lambda function to access S3 and SES.
resource "aws_iam_policy" "newsletter_policy" {
  name = "food-explorer-newsletter-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:*"]
        Resource = "${aws_s3_bucket.newsletter_bucket.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["ses:SendEmail", "ses:SendRawEmail"]
        Resource = "*"
      }
    ]
  })
}

# Define the IAM role for the Lambda function to use the policy.
resource "aws_iam_role" "newsletter_role" {
  name = "food-explorer-newsletter-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  # Attach the policy to the role.
  policy = aws_iam_policy.newsletter_policy.arn
}

# Define the Lambda function for sending newsletters.
resource "aws_lambda_function" "newsletter_function" {
  function_name = "food-explorer-newsletter-function"
  role          = aws_iam_role.newsletter_role.arn
  handler       = "lambda_function.send_newsletter"
  runtime       = "python3.9"
  filename      = "newsletter_function.zip"
  timeout       = 300

  environment {
    variables = {
      S3_BUCKET_NAME          = aws_s3_bucket.newsletter_bucket.id
      SES_SOURCE_EMAIL        = var.source_email_address
      SUBSCRIBERS_TABLE_NAME  = aws_dynamodb_table.subscribers.name
    }
  }
}

# Define the SNS topic for monitoring email sending.
resource "aws_sns_topic" "newsletter_topic" {
  name = "food-explorer-newsletter-topic"
}

# Define the SQS queue for email sending.
resource "aws_sqs_queue" "newsletter_queue" {
  name = "food-explorer-newsletter-queue"

  # Define the policy for the queue to allow SNS to send messages.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "Allow-SNS-SendMessage"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = "sqs:SendMessage"
        Resource = aws_sqs_queue.newsletter_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.newsletter_topic.arn
          }
        }
      }
    ]
  })

  # Define the subscription to the SNS topic.
  depends_on = [aws_sns_topic.newsletter_topic]
  dynamic "subscription" {
    for_each = var.email_subscribers
    content {
      protocol = "email"
      endpoint = subscription.value
    }
  }
}

# Define the Lambda function trigger for the SQS queue.
resource "aws_lambda_event_source_mapping" "newsletter_event_mapping" {
  event_source_arn = aws_sqs_queue.newsletter_queue.arn
  function_name    = aws_lambda_function.newsletter_function.arn
}
