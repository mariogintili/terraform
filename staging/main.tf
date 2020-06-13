provider "aws" {
  region = "us-east-1"
}

data "aws_availability_zones" "all" {}

resource "aws_launch_configuration" "example" {
  image_id               = "ami-40d28157"
  instance_type          = "t2.micro"
  security_groups = ["${aws_security_group.example.id}"]

  user_data = <<-EOF
   #!/bin/bash
   echo "Hello, Terraform 🥶" > index.html
   nohup busybox httpd -f -p "${var.server_port}"
  EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.id
  availability_zones = data.aws_availability_zones.all.names

  load_balancers = ["${aws_elb.example.name}"]
  health_check_type = "ELB"


  min_size = 2
  max_size = 4

  tag {
    key = "Name"
    value = "terraform-autoscaling-group-example"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "example" {
  name = "terraform-example-instance"
  # description = "This group allows incoming TCP requests on port 8080 from CIDR block 0.0.0.0/0. In english: this group allows all incoming requests on port 8080 from any IP"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "elb" {
  name = "terraform-example-elb"
  description = "Allows incoming requests on port 80, the default for HTTP to the AWS autoscaling group"

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # allows all incoming IPs
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elb" "example" {
  name = "tf-elb-example"
  availability_zones = data.aws_availability_zones.all.names
  security_groups = ["${aws_security_group.elb.id}"]

  listener {
    lb_port = 80 # the default port of HTTP
    lb_protocol = "http"
    instance_port = var.server_port
    instance_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:${var.server_port}/"
  }
}

resource "aws_s3_bucket" "mrg_staging_terraform_state" {
  bucket = "mrg-staging-terraform-state"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_dynamodb_table" "mrg_staging_terraform_lock" {
  name           = "mrg-staging-terraform-lock"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

terraform {
  backend "s3" {
    bucket         = "mrg-staging-terraform-state"
    key            = "infra/staging.tfstate"
    region         = "us-east-1"
    dynamodb_table = "mrg-staging-terraform-lock"
  }
}
