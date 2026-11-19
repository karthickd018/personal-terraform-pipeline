terraform {
  backend "s3" {
    # REPLACE with your EXISTING_S3_BUCKET and region before first pipeline run
    bucket = "REPLACE-ME-personal-tf-state-ACCOUNT_ID-REGION"
    key    = "statefile/environment-deployments/dev/dev-ec2/terraform.tfstate"
    region = "ap-south-1"
  }
}
