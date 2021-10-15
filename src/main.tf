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
    owner   = "Dakota"
  }
}

provider "aws" {
  region = local.region
}

resource "aws_vpc" "demo_vpc" {
  cidr_block = "10.0.0.0/16"
  tags       = local.common_tags
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.demo_vpc.id
  tags   = local.common_tags
}


resource "aws_subnet" "demo_subnet_public" {
  vpc_id     = aws_vpc.demo_vpc.id
  cidr_block = "10.0.1.0/24"
  tags       = local.common_tags
}


resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.demo_vpc.id

  route = [
    {
      cidr_block                 = "0.0.0.0/0"
      gateway_id                 = aws_internet_gateway.igw.id
      carrier_gateway_id         = ""
      destination_prefix_list_id = ""
      egress_only_gateway_id     = ""
      instance_id                = ""
      local_gateway_id           = ""
      nat_gateway_id             = ""
      network_interface_id       = ""
      transit_gateway_id         = ""
      vpc_endpoint_id            = ""
      vpc_peering_connection_id  = ""
      ipv6_cidr_block            = ""
    }
  ]

  tags = local.common_tags
}

module "session_manager" {
  source        = "git::https://github.com/tmknom/terraform-aws-session-manager.git?ref=tags/2.0.0"
  name          = "example"
  instance_type = "t2.micro"
  subnet_id     = demo_subnet_public.subnet_id
  vpc_id        = demo_vpc.vpc_id
}


resource "aws_route_table_association" "public_route_table_assoc" {
  subnet_id      = aws_subnet.demo_subnet_public.id
  route_table_id = aws_route_table.public_route_table.id
}


data "aws_secretsmanager_secret" "testing-secrets-in-state" {
  arn = "arn:aws:secretsmanager:us-east-2:391294193874:secret:terraform-testing-q2Lwwo"
}

data "aws_secretsmanager_secret_version" "retrieve-secret-value" {
  secret_id = data.aws_secretsmanager_secret.testing-secrets-in-state.id
}
