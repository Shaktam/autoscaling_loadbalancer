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
  value = aws_elb.weblb.dns_name
}