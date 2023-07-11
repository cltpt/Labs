# Create the Secret in AWS Secrets Manager
resource "aws_secretsmanager_secret" "my_secret" {
  name = "my_secret1"
}

# Create a Secret value in AWS Secrets Manager
resource "aws_secretsmanager_secret_version" "my_secret_value" {
  secret_id = aws_secretsmanager_secret.my_secret.id
  secret_string = jsonencode({
    "username" : "testusername",
    "password" : "testingpassword123!"
  })
}