terraform {
  backend "s3" {
    # REPLACE before first apply:
    #   bucket = your EXISTING_S3_BUCKET (state + env tfvars)
    #   region = your AWS region
    bucket = "REPLACE-ME-personal-tf-state-ACCOUNT_ID-REGION"
    key    = "statefile/deployment-pipeline/terraform.tfstate"
    region = "ap-south-1"
  }
}
