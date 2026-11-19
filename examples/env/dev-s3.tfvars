# Upload to: s3://<EXISTING_S3_BUCKET>/env/dev-s3.tfvars
# MODULE_PATH = environment-deployments/dev/dev-s3

bucket_name       = "personal-demo-dev-s3-REPLACE-ACCOUNT_ID"
environment       = "dev"
region            = "ap-south-1"
enable_versioning = true

tags = {
  Project = "personal-terraform-pipeline"
  Owner   = "karthick"
}
