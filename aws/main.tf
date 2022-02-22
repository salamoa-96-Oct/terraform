terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  region  = var.aws_region
  shared_credentials_file = var.aws_shared_credentials
}

################### VPC ########################

resource "aws_vpc" "mjs-vpc" {
  cidr_block           = var.aws_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Owner = "${var.owner}"
    Name = "mjs_vpc"
    Service = "k8s_mjs"
  }
}

################## IGW ######################
resource "aws_internet_gateway" "mjs-igw" {
  vpc_id = aws_vpc.mjs-vpc.id

  tags = {
    Owner = mjs
    Name = "mjs_igw"
    Service = "k8s_mjs"
  }
}

################# nat gateway ################

resource "aws_nat_gateway" "mjs-nat" {
  connectivity_type = "private"
  subnet_id         = aws_subnet.private_2.id
}

################# Routing table #################

resource "aws_route_table" "mjs_public_rt" {
  vpc_id = aws_vpc.mjs-vpc.id

  route {
    cidr_block = "::/0"
    gateway_id = aws_internet_gateway.mjs-igw.id
  }

  tags = {
    Owner = mjs
    Name = "mjs_public_rt"
    Service = "k8s_mjs"
  }
}

resource "aws_route_table" "mjs_pri_rt" {
  vpc_id = aws_vpc.mjs-vpc.id

  route {
    cidr_block = "::/0"
    gateway_id = aws_nat_gateway.mjs-nat.id
  }

  tags = {
    Owner = mjs
    Name = "mjs_pri_rt"
    Service = "k8s_mjs"
  }
}

################## Security Group ######################
resource "Security" "mjs_securitygroup" {
  name = "mjs_securitygroup"
  description = "Test_mjs"
  vpc_id = aws_vpc.mjs-vpc.id
  
   ingress {
    description      = "all Access"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_Access"
  }
}

#################### Subnet ###################
resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "pub-subnet-mjs"
  }
}