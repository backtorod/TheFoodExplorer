data "archive_file" "generate_newsletter_lambda_zip" {
  type        = "zip"
  source_dir = "../src"
  output_path = "../generate_newsletter_lambda.zip"
}

resource "aws_lambda_function" "generate_newsletter_lambda" {
  filename      = data.archive_file.generate_newsletter_lambda_zip.output_path
  function_name = "generate_newsletter_lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  timeout       = 30

  environment {
    variables = {
      REGION                  = var.region
      ASSUME_ROLE_ARN         = aws_iam_role.lambda_role.arn
      SOURCE_EMAIL            = var.source_email
      SUBSCRIBERS_TABLE_NAME  = aws_dynamodb_table.subscribers_table.name
      S3_BUCKET_NAME          = aws_s3_bucket.newsletter_bucket.id
    }
  }

  depends_on = [
    aws_iam_role.lambda_role,
    aws_s3_bucket_object.newsletter_object,
    aws_dynamodb_table.subscribers_table,
  ]
}

resource "aws_lambda_permission" "apigw_generate_newsletter_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.generate_newsletter_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.api.execution_arn}/*/*/*"
}
