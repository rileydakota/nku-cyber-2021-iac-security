terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
  backend "s3" {}
}

locals {
  region = "us-east-2"
  common_tags = {
      project = "nku-iac-security"
      owner = "Dakota"
  }
}

provider "aws" {
  region = local.region
}

resource "aws_vpc" "my_test_vpc" {
  cidr_block = "10.0.0.0/16"
  tags       = local.common_tags
}