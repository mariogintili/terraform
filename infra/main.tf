provider "aws" {
  region = "us-east-1"
}

variable "server_port" {
  default     = 8080
  description = "The port that the server will use for HTTP requests"
}

resource "aws_instance" "example" {
  ami                    = "ami-40d28157"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.example.id}"]

  user_data = <<-EOF
   #!/bin/bash
   echo "Hello, Terraform 🥶" > index.html
   nohup busybox httpd -f -p "${var.server_port}"
  EOF

  tags = {
    Name = "example-1"
  }
}

resource "aws_security_group" "example" {
  name = "terraform-example-instance"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "public_ip" {
  value = aws_instance.example.public_ip
  description = "The public IP address of my box"
}
