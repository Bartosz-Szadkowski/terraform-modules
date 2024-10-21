resource "aws_iam_role" "python_web_app_pod_role" {
  name = "python-web-app-pod-role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["sts:AssumeRole", "sts:TagSession"]
        Effect = "Allow"
        Sid    = "AllowEksAuthToAssumeRoleForPodIdentity"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    UsedByApp = "python-web-app"
  }
}

resource "aws_iam_role_policy" "python_web_app_pod_policy" {
  name = "python_web_app_pod_policy"
  role = aws_iam_role.python_web_app_pod_role.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:*",
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:s3:::application-bucket*",      
          "arn:aws:s3:::application-bucket*/*"     
        ]
      },
    ]
  })
}
