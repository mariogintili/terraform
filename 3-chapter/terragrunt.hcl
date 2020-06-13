remote_state {
  backend = "s3"

  config = {
    bucket  = "mrg-terraform-state"
    key     = "infra/terraform.tfstate"
    region  = "us-east-1"
  }
}
