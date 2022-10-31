
#" Create VPC"
resource "aws_vpc" "application_vpc" {
  cidr_block = "10.0.0.0/16"
   tags = {
    Name = "My VPC"
  }
}

# "Create Public Subnet1"
resource "aws_subnet" "public_subnet_a" {
  vpc_id     = aws_vpc.application_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Public Subnet 1"
  }
}
# "Create Public Subnet2"
resource "aws_subnet" "public_subnet_b" {
  vpc_id     = aws_vpc.application_vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "Public Subnet 2"
  }
}

# "Create Private Subnet1"
resource "aws_subnet" "private_subnet_a" {
  vpc_id     = aws_vpc.application_vpc.id
  cidr_block = "10.0.3.0/24"

  tags = {
    Name = "Public Subnet 1"
  }
}

# "Create Private Subnet2"
resource "aws_subnet" "private_subnet_b" {
  vpc_id     = aws_vpc.application_vpc.id
  cidr_block = "10.0.4.0/24"

  tags = {
    Name = "Public Subnet 2"
  }
}
#" Create Internet gateway"
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.application_vpc.id

  tags = {
    Name = "IGW"
  }
}

# Create Elastic IP for Private subnet NATgateway
resource "aws_eip" "nat_ip" {
  vpc      = true
   tags = {
    Name = "EIP Nat"
  }
}

#Create NAT gateway
resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.nat_ip.id
  subnet_id     = aws_subnet.public_subnet_a.id

  tags = {
    Name = "NAT GW"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}
# create default route table association
resource "aws_default_route_table" "private_route_table" {
  default_route_table_id = aws_vpc.application_vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.natgw.id
  }
  tags = {
    Name = "Private Route Table"
  }
}

# "Create public Route Table"
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.application_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "Public Route Table"
  }
}
# route_table_association for public_subnet_a
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_route_table.id
}
# route_table_association for public_subnet_b
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_route_table.id
}

# "Create Security Group"
resource "aws_security_group" "sg" {
  name        = "allow_http_ssh"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.application_vpc.id

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    security_groups = [ aws_security_group.allow_http_lb.id ]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Allow_HTTP_SSH"
  }
}