terraform {
  required_version = ">=0.12"
}


resource "aws_instance" "EC2" {
  ami			          = data.aws_ami.ubuntu.id
  instance_type           = "t2.micro"
  vpc_security_group_ids  = [aws_security_group.EC2SecurityGroup.id]

    tags = {
    Name = "ec2-instance"
  }

}

resource "aws_security_group" "EC2SecurityGroup" {
  name = "EC2Security"
  description = "http/ssh connect"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "EC2Security"
  }
}
