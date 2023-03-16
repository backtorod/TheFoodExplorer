data "archive_file" "subscribe_lambda_zip" {
  type        = "zip"
  source_dir = "../src"
  output_path = "../subscribe_lambda.zip"
}

resource "aws_lambda_function" "subscribe_lambda" {
  filename      = data.archive_file.subscribe_lambda_zip.output_path
  function_name = "subscribe_lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  timeout       = 30

  environment {
    variables = {
      REGION                  = var.region
      ASSUME_ROLE_ARN         = aws_iam_role.lambda_role.arn
      SUBSCRIBERS_TABLE_NAME  = aws_dynamodb_table.subscribers_table.name
    }
  }

  depends_on = [
    aws_iam_role.lambda_role,
    aws_dynamodb_table.subscribers_table,
  ]
}

resource "aws_lambda_permission" "apigw_subscribe_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.subscribe_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.api.execution_arn}/*/*/*"
}
