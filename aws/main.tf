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
    Owner   = "${var.owner}"
    Name    = "mjs_vpc"
    Service = "k8s_mjs"
  }
}


################## IGW ######################
resource "aws_internet_gateway" "mjs-igw" {
  vpc_id = aws_vpc.mjs-vpc.id

  tags = {
    Owner   = "${var.owner}"
    Name    = "mjs_igw"
    Service = "k8s_mjs"
  }
}


################# eip #################
resource "aws_eip" "bastion-eip" {
  instance = aws_instance.mjs-bastion.id
  vpc      = true
}


################# nat gateway ################
resource "aws_nat_gateway" "mjs-nat" {
  connectivity_type = "private"
  subnet_id         = aws_subnet.k8s_private_subnet_1.id
}


################# Routing table #################

resource "aws_route_table" "mjs-public-rt" {
  vpc_id = aws_vpc.mjs-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mjs-igw.id
  }

  tags = {
    Owner = "mjs"
    Name = "mjs_public_rt"
    Service = "k8s_mjs"
  }
}

resource "aws_route_table" "mjs-pri-rt" {
  vpc_id = aws_vpc.mjs-vpc.id

  route = []

  tags = {
    Owner = "mjs"
    Name = "mjs_pri_rt"
    Service = "k8s_mjs"
  }
}

################## Security Group ######################
resource "aws_security_group" "mjs-securitygroup" {
  name = "mjs-securitygroup"
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
resource "aws_security_group" "bastion_security_group" {
  name        = "${var.ec2_name}-bastion-sg"
  description = "Security Group for ${var.ec2_name} Bastion Host"
  vpc_id      = aws_vpc.mjs-vpc.id

  # --- SSH ---
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}
#################### Subnet ###################

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "k8s_private_subnet_1" {
  vpc_id                  = aws_vpc.mjs-vpc.id
  cidr_block              = var.aws_vpc_subnet_cidrs["private_1"]
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"
  tags = {
    Owner   = "${var.owner}"
    Name    = "tas-private-subnet-1"
    Service = "k8s_example"
  }
}

resource "aws_subnet" "k8s_public_subnet_1" {
  vpc_id                  = aws_vpc.mjs-vpc.id
  cidr_block              = var.aws_vpc_subnet_cidrs["public_1"]
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"
  tags = {
    Owner   = "${var.owner}"
    Name    = "tas-public-subnet-1"
    Service = "k8s_example"
  }
}

resource "aws_subnet" "k8s_private_subnet_2" {
  vpc_id                  = aws_vpc.mjs-vpc.id
  cidr_block              = var.aws_vpc_subnet_cidrs["private_2"]
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"
  tags = {
    Owner   = "${var.owner}"
    Name    = "tas-private-subnet-2"
    Service = "k8s_example"
  }
}

resource "aws_subnet" "k8s_public_subnet_2" {
  vpc_id                  = aws_vpc.mjs-vpc.id
  cidr_block              = var.aws_vpc_subnet_cidrs["public_2"]
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"
  tags = {
    Owner   = "${var.owner}"
    Name    = "tas-public-subnet-2"
    Service = "k8s_example"
  }
}

############### Routung table association #############

resource "aws_route_table_association" "k8s_public_association_1" {
  subnet_id      = aws_subnet.k8s_public_subnet_1.id
  route_table_id = aws_route_table.mjs-public-rt.id
}
resource "aws_route_table_association" "k8s_public_association_2" {
  subnet_id      = aws_subnet.k8s_public_subnet_2.id
  route_table_id = aws_route_table.mjs-public-rt.id
}
resource "aws_route_table_association" "k8s_private_association_1" {
  subnet_id      = aws_subnet.k8s_private_subnet_1.id
  route_table_id = aws_route_table.mjs-pri-rt.id
}
resource "aws_route_table_association" "k8s_private_association_2" {
  subnet_id      = aws_subnet.k8s_private_subnet_2.id
  route_table_id = aws_route_table.mjs-pri-rt.id
}
############### key Pair ################
resource "aws_key_pair" "aws_key" {
  key_name = var.ssh_key_name
  public_key = file(format("%s/%s.pub",var.ssh_key_path,var.ssh_key_name)) 
}

############### EC2 ##################
resource "aws_instance" "mjs-bastion" {
  ami           = var.instance_ami
  instance_type = var.instance_type
  key_name      = var.ssh_key_name

  associate_public_ip_address = true

  vpc_security_group_ids = ["${aws_security_group.bastion_security_group.id}"]
  subnet_id              = aws_subnet.k8s_public_subnet_1.id

  /*root_block_device {
    volume_type           = "gp2"
    volume_size           = "10"
    delete_on_termination = true
  }
*/
  tags = {
    Name = "${var.ec2_name}-bastion"
  }
}

################ EKS 구축 ##################
