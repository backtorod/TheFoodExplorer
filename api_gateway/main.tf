resource "aws_apigatewayv2_api" "api" {
  name          = "newsletter_api"
  protocol_type = "HTTP"

  tags = {
    Environment = var.environment
  }
}

resource "aws_apigatewayv2_integration" "generate_newsletter_integration" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.generate_newsletter_lambda.invoke_arn
  passthrough_behavior = "WHEN_NO_MATCH"

  depends_on = [
    aws_apigatewayv2_api.api,
    aws_lambda_function.generate_newsletter_lambda,
    aws_lambda_permission.apigw_generate_newsletter_permission,
  ]
}

resource "aws_apigatewayv2_integration" "subscribe_integration" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.subscribe_lambda.invoke_arn
  passthrough_behavior = "WHEN_NO_MATCH"

  depends_on = [
    aws_apigatewayv2_api.api,
    aws_lambda_function.subscribe_lambda,
    aws_lambda_permission.apigw_subscribe_permission,
  ]
}

resource "aws_apigatewayv2_route" "generate_newsletter_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /generate_newsletter"

  target = "integrations/${aws_apigatewayv2_integration.generate_newsletter_integration.id}"

  depends_on = [
    aws_apigatewayv2_api.api,
    aws_apigatewayv2_integration.generate_newsletter_integration,
  ]
}

resource "aws_apigatewayv2_route" "subscribe_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /subscribe"

  target = "integrations/${aws_apigatewayv2_integration.subscribe_integration.id}"

  depends_on = [
    aws_apigatewayv2_api.api,
    aws_apigatewayv2_integration.subscribe_integration,
  ]
}

resource "aws_apigatewayv2_stage" "stage" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "prod"
  auto_deploy = true

  depends_on = [
    aws_apigatewayv2_api.api,
    aws_apigatewayv2_route.generate_newsletter_route,
    aws_apigatewayv2_route.subscribe_route,
  ]
}
