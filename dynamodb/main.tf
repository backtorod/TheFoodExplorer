resource "aws_dynamodb_table" "subscribers_table" {
  name = "subscribers_table"

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

  billing_mode = "PAY_PER_REQUEST"

  hash_key = "email"

  tags = {
    Environment = var.environment
  }
}
