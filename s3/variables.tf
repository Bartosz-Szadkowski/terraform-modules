variable "bucket_prefix" {
  description = "The name of the S3 bucket"
  type        = string
}

variable "versioning_enabled" {
  description = "Enable versioning on the S3 bucket"
  type        = bool
  default     = true
}

variable "encryption_enabled" {
  description = "Enable server-side encryption using AES-256"
  type        = bool
  default     = true
}

variable "lifecycle_enabled" {
  description = "Enable lifecycle policy for transitioning or expiring objects"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to the bucket"
  type        = map(string)
  default     = {}
}

variable "python_web_app_pod_role_arn" {}

variable "region" {
  type    = string
  default = "us-east-1"
}