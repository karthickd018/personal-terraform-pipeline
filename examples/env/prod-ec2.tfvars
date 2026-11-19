# Upload to: s3://staging-terraform-tfstate-bucket/env/prod-ec2.tfvars
# MODULE_PATH = environment-deployments/prod/prod-ec2

name          = "personal-prod-ec2"
ami_id        = "ami-REPLACE_ME_AP_SOUTH_1"
instance_type = "t3.micro"
environment   = "prod"
region        = "ap-south-1"

tags = {
  Project = "personal-terraform-pipeline"
  Owner   = "karthickd018"
}
