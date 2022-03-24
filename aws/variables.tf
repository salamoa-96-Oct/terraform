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
  default     = "ami-0c02fb55956c7d316"
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

variable "subnet_cidrs_pri" {
  description = "Subnet CIDRs for public subnets (length must match configured availability_zones)"
  default = ["10.0.100.0/24", "10.0.200.0/24"]
  type = list
}

variable "availability_zones" {
  description = "AZs in this region to use"
  default = ["us-east-1a", "us-east-1c"]
  type = list
}

variable "ec2_name" {
  description = "ec2-name"
  default = "mjs-bastion"
}

variable "cluster_name" {
  default = "mjs-terraform-eks"
  type    = string
}

variable "enabled_cluster_log_types" {
  default = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  type = list
}

variable "public_access_cidrs" {
  default = ["0.0.0.0/0"]
  type = list
  
}

variable "cluster-name" {
  default = "mjs-terraform-eks"
  type    = string
}