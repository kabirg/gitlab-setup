####################################
#### SANDBOX ACCOUNT BOOTSTRAP #####
####################################

##############
## PROVIDER ##
##############
provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

###############
## VARIABLES ##
###############
variable "component_name" {
  type = string
  description = "Name-prefix for all account resources."
  default = "sandbox"
}

variable "vpc_cidr" {
  type = string
  description = "VPC CIDR"
  default = "10.0.0.0/16"
}

variable "subnet_cidrs" {
  type = map(string)
  description = "Map of subnet CIDR's w/two key/value pairs (for public/private subnets)."
  default = {
    public = "10.0.1.0/24",
    private = "10.0.10.0/24"
  }
}

# RHEL7 AMI
variable "instance_ami" {
  type = string
  description = "AMI for EC2 instance"
  default = "ami-2051294a"
}

# Gitlab requires an instance with at least 1 core and 8GB RAM minimum.
# https://docs.gitlab.com/ee/install/requirements.html#hardware-requirements
variable "instance_type" {
  type = string
  description = "Instance type"
  default = "m4.large"
}

# EC2 Keypair needs to pre-exist
variable "instance_key_pair" {
  type = string
  description = "Instance key pair name"
}

###############
## RESOURCES ##
###############

#VPC
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "${var.component_name}-vpc"
  }
}

#SUBNETS
resource "aws_subnet" "public-subnet" {
  availability_zone       = "us-east-1a"
  cidr_block              = var.subnet_cidrs.public
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.vpc.id
  tags = {
    Name = "${var.component_name}-public-subnet"
  }
}

resource "aws_subnet" "private-subnet" {
  cidr_block = var.subnet_cidrs.private
  vpc_id     = aws_vpc.vpc.id
  tags = {
    Name = "${var.component_name}-private-subnet"
  }
}

#IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.component_name}-igw"
  }
}

# SG
resource "aws_security_group" "public-sg" {
  name        = "${var.component_name}-public-sg"
  description = "Allow inbound ICMP/SSH/HTTP(s) traffic to the public subnet"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 2222
    to_port     = 2222
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

#ROUTE TABLE FOR PUBLIC SUBNET
resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${var.component_name}-public-rt"
  }
}

resource "aws_route_table_association" "public-rt-association" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.public-rt.id
}

# 2 INSTANCES (FOR THE GITLAB INSTANCE AND RUNNER)
resource "aws_instance" "instance" {
  count                       = 2
  ami                         = var.instance_ami
  associate_public_ip_address = true
  availability_zone           = "us-east-1a"
  instance_type               = var.instance_type
  key_name                    = var.instance_key_pair
  subnet_id                   = aws_subnet.public-subnet.id
  vpc_security_group_ids      = [aws_security_group.public-sg.id]
  tags = {
    Name = "${var.component_name}-instance"
  }

  # Installs Docker & Docker Compose on a RHEL8 Instance
  # user_data = <<-EOF
  #             #!/bin/bash
  #             dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
  #             dnf install docker-ce --nobest -y
  #             systemctl enable --now docker
  #             usermod -aG docker ec2-user
  #             EOF

  # Installs Docker & Docker Compose on an RHEL7 Instance
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y yum-utils device-mapper-persistent-data lvm2
              yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
              yum install -y http://mirror.centos.org/centos/7/extras/x86_64/Packages/container-selinux-2.107-3.el7.noarch.rpm
              yum install -y docker-ce docker-ce-cli containerd.io
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user
              curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
              chmod +x /usr/local/bin/docker-compose
              newgrp docker
              EOF
}

resource "aws_eip" "eip" {
  vpc = true
}

# EIP ONLY NEEDED FOR ONE INSTANCE (the one that will host the Gitlab container)
resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.instance.0.id
  allocation_id = aws_eip.eip.id
}

#############
## OUTPUTS ##
#############
output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "public_subnet_id" {
  value = aws_subnet.public-subnet.id
}

output "private_subnet_id" {
  value = aws_subnet.private-subnet.id
}

output "igw_id" {
  value = aws_internet_gateway.igw.id
}

output "public_sg_id" {
  value = aws_security_group.public-sg.id
}

output "public_rt_id" {
  value = aws_route_table.public-rt.id
}

output "ec2_instance_id" {
  value = aws_instance.instance.*.id
}

output "ec2_public_ip" {
  value = aws_eip.eip.public_ip
}
