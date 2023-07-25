provider "aws" {
  region  = "us-west-2"
  profile = "main-test"
}

locals {
  common_tags = {
    Terraform   = "true"
    Environment = "dev-0"
    Demo        = "true"
  }
}

data "aws_security_group" "temabit_sg" {
  tags = {
    "Demo" = "true"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

module "ec2_instance" {
  source                      = "terraform-aws-modules/ec2-instance/aws"
  version                     = "~> 4.0"
  name                        = "app-instance"
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.app_instance_type
  key_name                    = var.aws_key_name
  vpc_security_group_ids      = [data.aws_security_group.temabit_sg.id]
  associate_public_ip_address = true
  monitoring                  = true

  root_block_device = [
    {
      encrypted   = true
      volume_type = "gp3"
      throughput  = 200
      volume_size = 50
    },
  ]

  metadata_options = {
    http_tokens = "required"
  }

  tags = local.common_tags

  enable_volume_tags = true

  putin_khuylo = true
}

# Checks
check "public_ip_assign" {
  assert {
    condition = module.ec2_instance.public_ip == null
    error_message = "ERROR: EC2 instance with public IP"
  }
}
