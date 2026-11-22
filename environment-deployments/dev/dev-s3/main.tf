# Dev S3 deployment — used to validate PR plan + controlled deploy
module "s3" {
  source = "../../../reusable-modules/s3"

  bucket_name       = var.bucket_name
  environment       = var.environment
  enable_versioning = var.enable_versioning
  tags              = var.tags
}

output "bucket_id" {
  description = "ID of the dev S3 bucket"
  value       = module.s3.bucket_id
}

output "bucket_arn" {
  description = "ARN of the dev S3 bucket"
  value       = module.s3.bucket_arn
}
