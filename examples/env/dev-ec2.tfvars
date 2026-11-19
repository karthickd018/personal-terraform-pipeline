# Upload to: s3://<EXISTING_S3_BUCKET>/env/dev-ec2.tfvars
# MODULE_PATH = environment-deployments/dev/dev-ec2
#
# Find a current Amazon Linux 2023 AMI for your region, e.g.:
#   aws ec2 describe-images --owners amazon \
#     --filters "Name=name,Values=al2023-ami-2023*-x86_64" \
#     --query 'sort_by(Images,&CreationDate)[-1].ImageId' --output text

name          = "personal-dev-ec2"
ami_id        = "ami-REPLACE_ME"
instance_type = "t3.micro"
environment   = "dev"
region        = "ap-south-1"

tags = {
  Project = "personal-terraform-pipeline"
  Owner   = "karthick"
}
