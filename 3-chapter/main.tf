provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "mrg_terraform_state" {
  bucket = "mrg-terraform-state"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_dynamodb_table" "mrg_terraform_lock" {
  name           = "mrg-terraform-lock"
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
    bucket         = "mrg-terraform-state"
    key            = "infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "mrg-terraform-lock"
  }
}
