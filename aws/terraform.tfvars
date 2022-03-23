aws_region   = "us-east-1"
aws_vpc_cidr = "10.0.0.0/16"
aws_vpc_subnet_cidrs = {
  public_1  = "10.0.1.0/24"
  public_2  = "10.0.2.0/24"
  private_1 = "10.0.100.0/24"
  private_2 = "10.0.200.0/24"
}

ssh_key_name        = "terraform-test-key"
ssh_key_path        = "~/.ssh"
ssh_public_key_path = "~/.ssh"

instance_type       = "t2.micro"
instance_ami        = "ami-04505e74c0741db8d"