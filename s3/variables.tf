variable "bucket_prefix" {
  description = "The name of the S3 bucket"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the bucket"
  type        = map(string)
  default     = {}
}

variable "python_web_app_pod_role_arn" {
  type = string
}

variable "region" {
  type    = string
  default = "us-east-1"
}