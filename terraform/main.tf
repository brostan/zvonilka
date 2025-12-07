provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "jitsi_meet" {
  ami           = "ami-0c55b159cbfafe1f0" # Replace with a valid AMI ID
  instance_type = "t2.micro"

  tags = {
    Name = "JitsiMeetServer"
  }
}

resource "aws_security_group" "jitsi_sg" {
  name        = "jitsi_security_group"
  description = "Allow access to Jitsi Meet server"

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
    from_port   = 10000
    to_port     = 20000
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "jitsi_meet" {
  ami           = "ami-0c55b159cbfafe1f0" # Replace with a valid AMI ID
  instance_type = "t2.micro"
  security_groups = [aws_security_group.jitsi_sg.name]

  tags = {
    Name = "JitsiMeetServer"
  }
}