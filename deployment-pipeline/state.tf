terraform {
  backend "s3" {
    bucket = "staging-terraform-tfstate-bucket"
    key    = "statefile/deployment-pipeline/terraform.tfstate"
    region = "ap-south-1"
  }
}
