terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.48"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.32"
    }
  }
  required_version = ">= 1.3.0"
}

provider "aws" {
  # Generate key from: https://us-east-1.console.aws.amazon.com/iamv2/home#/users
  # export AWS_ACCESS_KEY_ID="youraccessid"
  # export AWS_SECRET_ACCESS_KEY="yoursecretkey"
  # access_key = "youraccessid"
  # secret_key = "yoursecretkey"
  region = var.region
}

resource "aws_key_pair" "csaf" {
  key_name   = var.name
  public_key = file("../csaf_rsa.pub")
}

resource "aws_instance" "csaf" {
  ami                    = "ami-02045ebddb047018b" # Ubuntu 22.04
  instance_type          = var.package
  key_name               = aws_key_pair.csaf.key_name
  vpc_security_group_ids = [aws_security_group.csaf.id]
  subnet_id              = aws_subnet.csaf.id
  user_data              = file("../startup.sh")

  tags = {
    Name = var.name
  }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 100
    delete_on_termination = true
    encrypted             = false
  }
}

resource "aws_security_group" "csaf" {
  name        = var.name
  description = "CSAF Security Group"
  vpc_id      = aws_vpc.csaf.id

  tags = {
    Name = var.name
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc" "csaf" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = var.name
  }
}

resource "aws_subnet" "csaf" {
  vpc_id            = aws_vpc.csaf.id
  cidr_block        = "10.0.37.0/24"
  availability_zone = var.zone
  tags = {
    Name = var.name
  }
}

resource "aws_route_table" "csaf" {
  vpc_id =  aws_vpc.csaf.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.csaf.id
  }
  tags = {
    Name = var.name
  }
}

resource "aws_route_table_association" "csaf" {
  subnet_id      = aws_subnet.csaf.id
  route_table_id = aws_route_table.csaf.id
}

resource "aws_internet_gateway" "csaf" {
  tags = {
    Name = var.name
  }
}

resource "aws_internet_gateway_attachment" "csaf" {
  vpc_id              = aws_vpc.csaf.id
  internet_gateway_id = aws_internet_gateway.csaf.id
}

resource "aws_eip" "csaf" {
  instance = aws_instance.csaf.id
  tags = {
    Name = var.name
  }
}

resource "aws_eip_association" "csaf" {
  instance_id   = aws_instance.csaf.id
  allocation_id = aws_eip.csaf.id
}

provider "cloudflare" {
  # Generate token (Global API Key) from: https://dash.cloudflare.com/profile/api-tokens
  # export CLOUDFLARE_EMAIL="yourmail"
  # export CLOUDFLARE_API_KEY="yourkey"
  # email   = "yourmail"
  # api_key = "yourkey"
}

data "cloudflare_zone" "csaf" {
  name = var.domain
}

resource "cloudflare_record" "csaf" {
  name    = "aws"
  value   = aws_eip.csaf.public_ip
  type    = "A"
  proxied = false
  zone_id = data.cloudflare_zone.csaf.id
}