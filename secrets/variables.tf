variable "allowed_roles" {
  description = "List of IAM ARNs (roles or users) allowed to access the secret"
  type        = list(string)
}

variable "region" {
  default = "us-east-1"
}