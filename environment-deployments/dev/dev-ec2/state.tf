terraform {
  backend "s3" {
    bucket = "staging-terraform-tfstate-bucket"
    key    = "statefile/environment-deployments/dev/dev-ec2/terraform.tfstate"
    region = "ap-south-1"
  }
}
