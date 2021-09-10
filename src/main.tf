locals {
  region = "us-east-2"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
  backend "s3" {
    bucket = "terraform-state-bucket-39129419387"
    key    = "terraform.tfstate"
    region = local.region
  }
}

provider "aws" {
  region = local.region
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags       = {}
}