locals {
  name_prefix          = "${var.COMMON_NAME}-${var.ENVIRONMENT}-deployment-pipeline"
  pipeline_bucket_name = format("%s-%s-deployment-pipeline-%s-%s", var.COMMON_NAME, var.ENVIRONMENT, var.ACCOUNT_ID, var.REGION)
}
