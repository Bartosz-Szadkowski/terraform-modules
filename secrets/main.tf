provider "aws" {
  region = var.region
}

resource "random_password" "argocd_password" {
  length = 16
  upper  = true
  lower  = true
}

resource "aws_secretsmanager_secret" "argocd_secret" {
  name = "argocd-password"
}

resource "aws_secretsmanager_secret_version" "argocd_secret_version" {
  secret_id     = aws_secretsmanager_secret.argocd_secret.id
  secret_string = random_password.argocd_password.result
}

data "aws_caller_identity" "current" {}

resource "aws_secretsmanager_secret_policy" "argocd_secret_policy" {
  secret_arn = aws_secretsmanager_secret.argocd_secret.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = aws_secretsmanager_secret.argocd_secret.arn
        Principal = {
          AWS = var.allowed_roles
        }
      },
      {
        Effect : "Deny",
        Action : "secretsmanager:GetSecretValue",
        Resource : aws_secretsmanager_secret.argocd_secret.arn,
        Condition : {
          StringNotEquals : {
            "aws:PrincipalArn" : var.allowed_roles
          }
        },
        Principal : "*"
      }
    ]
  })
}
