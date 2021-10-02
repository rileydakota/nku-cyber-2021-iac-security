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
  aws_ak = "AKIAXYZDQCEN6OHMNKU3"
}

provider "aws" {
  region = local.region
}

resource "aws_vpc" "my_test_vpc" {
  cidr_block = "10.0.0.0/16"
  tags       = local.common_tags
}

data "aws_secretsmanager_secret" "testing-secrets-in-state" {
  arn = "arn:aws:secretsmanager:us-east-2:391294193874:secret:terraform-testing-q2Lwwo"
}

data "aws_secretsmanager_secret_version" "retrieve-secret-value" {
  secret_id = data.aws_secretsmanager_secret.testing-secrets-in-state.id
}
