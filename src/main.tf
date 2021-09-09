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
    region = "us-east-2"
  }
}





provider "aws" {
  region = "us-east-2"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}