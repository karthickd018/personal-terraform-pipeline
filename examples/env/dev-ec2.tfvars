# Upload to: s3://staging-terraform-tfstate-bucket/env/dev-ec2.tfvars
# MODULE_PATH = environment-deployments/dev/dev-ec2
#
# Set ami_id for ap-south-1 before first EC2 deploy, e.g.:
#   aws ec2 describe-images --region ap-south-1 --owners amazon \
#     --filters "Name=name,Values=al2023-ami-2023*-x86_64" \
#     --query 'sort_by(Images,&CreationDate)[-1].ImageId' --output text

name          = "personal-dev-ec2"
ami_id        = "ami-REPLACE_ME_AP_SOUTH_1"
instance_type = "t3.micro"
environment   = "dev"
region        = "ap-south-1"

tags = {
  Project = "personal-terraform-pipeline"
  Owner   = "karthickd018"
}
