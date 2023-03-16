terraform {
  required_version = ">= 1.0.0"
  backend "s3" {}
}

provider "aws" {
  region = var.region
}

module "providers" {
  source = "./providers"
}

module "iam" {
  source = "./iam"

  environment = var.environment
}

module "dynamodb" {
  source = "./dynamodb"

  environment = var.environment
}

module "s3" {
  source = "./s3"

  environment = var.environment
}

module "lambda_generate_newsletter" {
  source = "./lambda_generate_newsletter"

  region       = var.region
  source_email = var.source_email

  subscribers_table_name = module.dynamodb.subscribers_table_name
}

module "lambda_subscribe" {
  source = "./lambda_subscribe"

  region                  = var.region
  subscribers_table_name  = module.dynamodb.subscribers_table_name
}

module "apigateway" {
  source = "./apigateway"

  environment               = var.environment
  generate_newsletter_lambda = module.lambda_generate_newsletter.generate_newsletter_lambda
  subscribe_lambda          = module.lambda_subscribe.subscribe_lambda
}
