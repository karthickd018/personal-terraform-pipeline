terraform {
  backend "s3" {
    bucket = "staging-terraform-tfstate-bucket"
    key    = "statefile/environment-deployments/prod/prod-s3/terraform.tfstate"
    region = "ap-south-1"
  }
}
