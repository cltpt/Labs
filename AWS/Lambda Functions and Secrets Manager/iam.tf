# Create an IAM role for the Lambda function
resource "aws_iam_role" "lambda_role" {
  name               = "lambda_secrets_manager_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach the necessary policies to the IAM role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

resource "aws_iam_policy" "iam_policy_example" {
  name        = "SecretsManagerReadOnlyAccess"
  description = "Allows secretsmanager:GetSecretValue and secretsmanager:ListSecrets for all resources"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowSecretsManagerAccess",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:ListSecrets"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "secrets_manager_policy_attachment" {
  policy_arn = "arn:aws:iam::211522303738:policy/SecretsManagerReadOnlyAccess"
  role       = aws_iam_role.lambda_role.name
}