# Upload to: s3://staging-terraform-tfstate-bucket/env/prod-s3.tfvars
# MODULE_PATH = environment-deployments/prod/prod-s3

bucket_name       = "personal-demo-prod-s3-599524094747"
environment       = "prod"
region            = "ap-south-1"
enable_versioning = true

tags = {
  Project = "personal-terraform-pipeline"
  Owner   = "karthickd018"
}
