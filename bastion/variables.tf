variable "region" {
  default = "us-east-1"
}

variable "vpc_id" {
  description = "The ID of the VPC where the bastion host will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "The IDs of the subnets where the bastion host will be placed"
  type        = list(string)
}

variable "instance_type" {
  description = "Instance type for the bastion host"
  type        = string
  default     = "t2.micro"
}

variable "tags" {
  type = map(string)
  default = {
    Terraform   = "true"
    Environment = "dev"
    Purpose     = "bastion"
  }
}

variable "bastion_name" {
  type    = string
  default = "bastion"
}