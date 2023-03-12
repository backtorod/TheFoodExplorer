# Define variables for the primary AWS region.
variable "aws_primary_region" {
  type    = string
  default = "ca-central-1"
}

# Define variables for the secondary AWS region.
variable "aws_secondary_region" {
  type    = string
  default = "us-west-1"
}

# Define variables for the S3 bucket.
variable "s3_bucket_name" {
  type    = string
  default = "thefoodexplorer-data"
}

# Define variables for the S3 bucket containint the Terraform state
variable "s3_bucket_name_state" {
  type    = string
  default = "thefoodexplorer-state"
}

# Define variables for the DynamoDB table.
variable "subscribers_table_name" {
  type    = string
  default = "the-food-explorer-subscribers"
}

# Define variables for the email sender.
variable "source_email_address" {
  type    = string
  default = "me@backtorod.com"
}

# Define variables for the CloudWatch Events rule.
variable "schedule_expression" {
  type    = string
  default = "cron(0 8 * * ? *)"
}
