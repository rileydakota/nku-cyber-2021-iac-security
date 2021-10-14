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

resource "aws_security_group" "block_all_inbound" {

  name        = "block_all_inbound"
  description = "Blocks all inbound traffic while allowing outbound"
  vpc_id      = aws_vpc.demo_vpc.id
  ingress = [{
    description      = "very insecure rule"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }]

  egress = [{
    description      = "allow all outbound"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }]


  tags = local.common_tags
}
resource "aws_subnet" "demo_subnet_public" {
  vpc_id     = aws_vpc.demo_vpc.id
  cidr_block = "10.0.1.0/24"
  tags       = local.common_tags
}


resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon-linux-2.id
  instance_type               = "t3.micro"
   #checkov:skip=CKV_AWS_88:This instance communicates with the public ssm endpoint
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.demo_subnet_public.id
  vpc_security_group_ids      = [aws_security_group.block_all_inbound.id]
  iam_instance_profile        = aws_iam_instance_profile.ssm_managed_instance_prof.name
  tags                        = local.common_tags
  monitoring                  = true

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    http_endpoint               = "enabled"
  }
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

resource "aws_route_table_association" "public_route_table_assoc" {
  subnet_id      = aws_subnet.demo_subnet_public.id
  route_table_id = aws_route_table.public_route_table.id
}
resource "aws_iam_instance_profile" "ssm_managed_instance_prof" {
  role = aws_iam_role.ssm_managed_role.name
}

resource "aws_iam_role" "ssm_managed_role" {
  path                = "/"
  managed_policy_arns = ["bad_policy.arn"]
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}
data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}

resource "aws_iam_policy" "bad_policy" {
  name = "bad_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "*"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

data "aws_secretsmanager_secret" "testing-secrets-in-state" {
  arn = "arn:aws:secretsmanager:us-east-2:391294193874:secret:terraform-testing-q2Lwwo"
}

data "aws_secretsmanager_secret_version" "retrieve-secret-value" {
  secret_id = data.aws_secretsmanager_secret.testing-secrets-in-state.id
}
