# Create the Lambda function
resource "aws_lambda_function" "lambda_function" {
  function_name    = "random_function_name"
  layers           = ["arn:aws:lambda:us-east-1:put_your_account_number_here:layer:AWS-Parameters-and-Secrets-Lambda-Extension:4"]
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function_python.lambda_handler"
  runtime          = "python3.9"
  filename         = "lambda_function_python.zip"
  source_code_hash = filebase64sha256("lambda_function_python.zip")

  environment {
    variables = {
      PARAMETERS_SECRETS_EXTENSION_HTTP_PORT = "2773"
      SSM_PARAMETER_STORE_TTL                = "120"
      SECRETS_MANAGER_TTL                    = "120"
    }
  }
}