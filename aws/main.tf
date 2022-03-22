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
resource "aws_eks_cluster" "mjs-terraform-eks" {
  name     = "mjs-terraform-eks"
  version  = "1.21"
  role_arn = aws_iam_role.mjs-eks-iam.arn

  vpc_config {
    subnet_ids = [aws_subnet.k8s_private_subnet_1.id, aws_subnet.k8s_private_subnet_2.id]
    security_group_ids = "mjs-securitygroup"
    endpoint_private_access = true
    endpoint_public_access = true
    public_access_cidrs = "0.0.0.0/0"
  }
  kubernetes_network_config {
    service_ipv4_cidr = "172.20.0.0/16"
  }
  timeouts {
    create = ""
    update = ""
    delete = "" 
  }
  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.mjs-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.mjs-AmazonEKSVPCResourceController,
    aws_cloudwatch_log_group.mjs-eks-cluster-log,
  ]
}
  enabled_cluster_log_types = ["api", "audit"]
  name                      = var.cluster_name
output "endpoint" {
  value = aws_eks_cluster.mjs-terraform-eks.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.mjs-terraform-eks.certificate_authority[0].data
}

################# IAM Role for EKS Cluster #################
resource "aws_iam_role" "mjs-eks-iam" {
  name = "mjs-eks"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "mjs-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.mjs-eks-iam.name
}

# Optionally, enable Security Groups for Pods
# Reference: https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html
resource "aws_iam_role_policy_attachment" "mjs-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.mjs-eks-iam.name
}

##################### Control Plane Logging ##################
resource "aws_cloudwatch_log_group" "mjs-cloudwatch" {
  # The log group name format is /aws/eks/<cluster-name>/cluster
  # Reference: https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 3

  # ... potentially other configuration ...
}

#################### IAM Roles for Service Account ##################
data "tls_certificate" "mjs-eks-tls" {
  url = aws_eks_cluster.mjs-terraform-eks.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "mjs-eks-provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.mjs-terraform-eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.mjs-terraform-eks.identity[0].oidc[0].issuer
}

data "aws_iam_policy_document" "example_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.mjs-eks-provider.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.mjs-eks-provider.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "example" {
  assume_role_policy = data.aws_iam_policy_document.example_assume_role_policy.json
  name               = "example"
}


################### EKS Node-Group ########################
resource "aws_eks_node_group" "example" {
  cluster_name    = aws_eks_cluster.example.name
  node_group_name = "example"
  node_role_arn   = aws_iam_role.example.arn
  subnet_ids      = aws_subnet.example[*].id

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  update_config {
    max_unavailable = 2
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.example-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.example-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.example-AmazonEC2ContainerRegistryReadOnly,
  ]
}

################### EKS Node-Group IAM-Role ########################
resource "aws_iam_role" "example" {
  name = "eks-node-group-example"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "example-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.example.name
}

resource "aws_iam_role_policy_attachment" "example-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.example.name
}

resource "aws_iam_role_policy_attachment" "example-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.example.name
}

##################### Subnet for EKS Node Group ##################
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "example" {
  count = 2

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(aws_vpc.example.cidr_block, 8, count.index)
  vpc_id            = aws_vpc.example.id

  tags = {
    "kubernetes.io/cluster/${aws_eks_cluster.example.name}" = "shared"
  }
}
