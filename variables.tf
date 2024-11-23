

# variables.tf
variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "default_tags" {
  description = "Default tags for all resources"
  type        = map(string)
  default     = {}
}

variable "public_vpc_cidr" {
  description = "CIDR block for public VPC"
  type        = string
}

variable "private_vpc_cidr" {
  description = "CIDR block for private VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
}

variable "availability_zone" {
  description = "Availability zone for resources"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for EC2 instance"
  type        = string
}

# outputs.tf
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.main.id
}

output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.main.public_ip
}

output "ssm_connection_command" {
  description = "AWS CLI command to connect to the instance via SSM"
  value       = "aws ssm start-session --target ${aws_instance.main.id} --region ${var.aws_region}"
}


# In variables.tf, add these new variables:
variable "ssh_public_key" {
  description = "SSH public key for EC2 instance access"
  type        = string
  sensitive   = true
}
