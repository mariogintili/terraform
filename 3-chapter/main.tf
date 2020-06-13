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
