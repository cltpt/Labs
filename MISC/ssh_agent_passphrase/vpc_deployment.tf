resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "main_VPC"
  }
}

resource "aws_subnet" "private_sub" {
  cidr_block        = var.priv_cidr
  availability_zone = var.subnet_az_priv
  vpc_id            = aws_vpc.main.id
  tags = {
    Name = "private_subnet"
  }
}

resource "aws_subnet" "public_sub" {
  cidr_block              = var.pub_cidr
  availability_zone       = var.subnet_az_pub
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = "true" # This is what makes it a public subnet
  tags = {
    Name = "public_subnet"
  }
}

resource "aws_internet_gateway" "prod-igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "prod_igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.prod-igw.id
  }

  tags = {
    Name = "prod_public"
  }
}

resource "aws_route_table_association" "pub_rt_association" {
  subnet_id      = aws_subnet.public_sub.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "private_route_table"
  }
}

resource "aws_route_table_association" "private_rt_association" {
  count          = "1"
  subnet_id      = aws_subnet.private_sub.id
  route_table_id = aws_route_table.private-route-table.id

}

resource "aws_eip" "eip" {
  vpc = true
  tags = {
    Name = "NAT_eip"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public_sub.id

  tags = {
    Name = "NAT_GW"
  }
}

resource "aws_security_group" "ec2_sg" {
  name   = "allow_SSH"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "SSH from other machines in subnet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "server_sg_ssh"
  }
}