# AWS ----------------------------------------
variable "aws_region" {}
variable "aws_shared_credentials" {
  default = "aws.credentials"
}
variable "aws_vpc_cidr" {}
variable "aws_vpc_subnet_cidrs" {}

# SSH ----------------------------------------
variable "ssh_key_path" {}
variable "ssh_key_name" {}

# Instances ----------------------------------------
variable "instance_ami" {
  description = "ami of instances"
  default     = "ami-0454bb2fefc7de534"
}

variable "instance_type" {
  default = "t2.medium"
}

variable "owner" {
  default = "mjs"
}

variable "subnet_cidrs_public" {
  description = "Subnet CIDRs for public subnets (length must match configured availability_zones)"
  default = ["10.0.10.0/24", "10.0.20.0/24"]
  type = list
}

variable "availability_zones" {
  description = "AZs in this region to use"
  default = ["us-east-1a", "us-east-1c"]
  type = list
}