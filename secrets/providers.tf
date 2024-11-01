provider "aws" {
  region = var.region
}

provider "random" {}

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.73.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.3"
    }
  }
}