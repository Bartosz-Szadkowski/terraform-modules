variable "region" {
  type = string
  default = "us-east-1"
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "vpc_cidr_block" {}

variable "public_subnets_cidr_blocks" {
  type = list(string)
}

variable "private_subnets_eks_cidr_blocks" {
  type = list(string)
}

variable "private_subnets_rds_cidr_blocks" {
  type = list(string)
}

variable "tags" {
  type = map(string)
  default = {
    Terraform   = "true"
    Environment = "dev"
  }
}

