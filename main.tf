# main.tf
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.31"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.default_tags
  }
}

# VPCs
resource "aws_vpc" "public" {
  cidr_block           = var.public_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "${var.prefix}-public-vpc"
  }
}

resource "aws_vpc" "private" {
  cidr_block           = var.private_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.prefix}-private-vpc"
  }
}

# Public VPC Resources
resource "aws_internet_gateway" "public" {
  vpc_id = aws_vpc.public.id

  tags = {
    Name = "${var.prefix}-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                          = aws_vpc.public.id
  cidr_block                      = var.public_subnet_cidr
  availability_zone               = var.availability_zone
  map_public_ip_on_launch        = true
  enable_resource_name_dns_a_record_on_launch = true

  tags = {
    Name = "${var.prefix}-public-subnet"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.public.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.public.id
  }

  tags = {
    Name = "${var.prefix}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Private VPC Resources
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.private.id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = var.availability_zone
  
  tags = {
    Name = "${var.prefix}-private-subnet"
  }
}

resource "aws_security_group" "instance" {
  name_prefix = "${var.prefix}-instance-sg"
  description = "Security group for EC2 instance"
  vpc_id      = aws_vpc.public.id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "SSH access"
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.prefix}-instance-sg"
  }
}


# Network ACLs
resource "aws_network_acl" "public" {
  vpc_id = aws_vpc.public.id
  subnet_ids = [aws_subnet.public.id]

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "${var.prefix}-public-nacl"
  }
}

# SSM IAM Role and Instance Profile
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ssm" {
  name_prefix        = "${var.prefix}-ssm-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  # Recommended for production: Add inline boundary policy
  # permissions_boundary = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/boundary-policy"
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  name_prefix = "${var.prefix}-ssm-profile"
  role        = aws_iam_role.ssm.name
}



# Update the EC2 instance resource to include the key pair:
resource "aws_instance" "main" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  iam_instance_profile   = aws_iam_instance_profile.ssm.name
  vpc_security_group_ids = [aws_security_group.instance.id]
  key_name              = aws_key_pair.instance_key.key_name

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.prefix}-instance"
  }
}



# Add key pair resource:
resource "aws_key_pair" "instance_key" {
  key_name_prefix = "${var.prefix}-key"
  public_key      = var.ssh_public_key

  tags = {
    Name = "${var.prefix}-key"
  }
}

