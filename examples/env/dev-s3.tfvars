# Upload to: s3://staging-terraform-tfstate-bucket/env/dev-s3.tfvars
# MODULE_PATH = environment-deployments/dev/dev-s3

bucket_name       = "personal-demo-dev-s3-599524094747"
environment       = "dev"
region            = "ap-south-1"
enable_versioning = true

tags = {
  Project = "personal-terraform-pipeline"
  Owner   = "karthickd018"
  Purpose = "ci-cd-demo"
}
