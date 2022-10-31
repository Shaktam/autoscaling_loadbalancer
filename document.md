
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
  name        = "Allow_HTTP_SSH"
  description = "Allow HTTP SSH inbound traffic"
  vpc_id      = aws_vpc.application_vpc.id

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
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
 
 
 # Create Instance
resource "aws_instance" "webserver" {

  ami                         = "ami-0d593311db5abb72b"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  subnet_id                  = aws_subnet.public_subnet_a.id
  vpc_security_group_ids     = [aws_security_group.sg.id]
  key_name                   = "vockey"
  user_data                  = file("userdata.sh")
  tags = {
    Name = "Apaca Webserver"
  }
}
# OUTPUT
output "ec2_public_ip" {
  value = aws_instance.webserver.public_ip
}

# Create load Balancer Target Group
resource "aws_lb_target_group" "elb_tg" {
  name     = "ELBwebserver"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.application_vpc.id
}



# "Create Security Group"
resource "aws_security_group" "allow_http_lb" {
  name        = "HTTP"
  description = "Allow HTTP"
  vpc_id      = aws_vpc.application_vpc.id

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Allow_HTTP"
  }
}

# Create a new load balancer
resource "aws_elb" "weblb" {
  name               = "webelb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_http_lb.id]
  subnets            = [aws_subnet.public_subnet_a.id,aws_subnet.public_subnet_b.id]
  }

#Create load Balancer listener
resource "aws_lb_listener" "webserver" {
  load_balancer_arn = aws_lb.weblb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.elb_tg.arn
  }
}

# OUTPUT
output "lb_public_dns_name" {
  value = aws_lb.web_lb.dns_name
}


# AWS launch template

resource "aws_launch_template" "template" {
  name = "launch-template-terraform"

  credit_specification {
    cpu_credits = "standard"
  }

  image_id = "ami-0d593311db5abb72b"

  instance_initiated_shutdown_behavior = "terminate"

  instance_type = "t3.micro"


  key_name = "vockey"

  vpc_security_group_ids = [aws_security_group.allow_http_ssh.id]


  user_data = filebase64("userdata.sh")
}

# AWS Autoscaling Group
resource "aws_autoscaling_group" "autoscalewebserver" {
  vpc_zone_identifier = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
  desired_capacity    = 2
  max_size            = 3
  min_size            = 1

  launch_template {
    id      = aws_launch_template.template.id
    version = "$Latest"
  }
}
# AWS autoscaling Attachment
resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = aws_autoscaling_group.autoscalewebserver.id
  lb_target_group_arn    = aws_lb_target_group.webserver_target.arn
}