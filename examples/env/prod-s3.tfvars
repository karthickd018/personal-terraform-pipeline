# Upload to: s3://<EXISTING_S3_BUCKET>/env/prod-s3.tfvars
# MODULE_PATH = environment-deployments/prod/prod-s3

bucket_name       = "personal-demo-prod-s3-REPLACE-ACCOUNT_ID"
environment       = "prod"
region            = "ap-south-1"
enable_versioning = true

tags = {
  Project = "personal-terraform-pipeline"
  Owner   = "karthick"
}
