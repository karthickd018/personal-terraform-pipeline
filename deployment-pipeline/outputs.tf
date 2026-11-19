output "pipeline_name" {
  description = "Name of the universal Terraform pipeline"
  value       = aws_codepipeline.terraform.name
}

output "pipeline_arn" {
  description = "ARN of the pipeline"
  value       = aws_codepipeline.terraform.arn
}

output "codestar_connection_arn" {
  description = "GitHub CodeStar connection ARN referenced by the pipeline (manually created and managed outside Terraform)"
  value       = var.CODESTAR_CONNECTION_ARN
}

output "pipeline_notification_rule_arn" {
  description = "CodeStar Notification Rule ARN — publishes pipeline events to SNS → Chatbot → MS Teams"
  value       = aws_codestarnotifications_notification_rule.pipeline.arn
}

output "pipeline_bucket_name" {
  description = "S3 bucket storing pipeline artifacts and tfplan files"
  value       = aws_s3_bucket.pipeline.bucket
}

output "kms_key_arn" {
  description = "KMS CMK ARN used to encrypt the pipeline bucket"
  value       = aws_kms_key.pipeline.arn
}

output "pipeline_notifications_sns_topic_arn" {
  description = "SNS topic receiving CodeStar Notification events → forwarded to MS Teams via Chatbot"
  value       = aws_sns_topic.pipeline_notifications.arn
}

output "chatbot_configuration_arn" {
  description = "Amazon Q Developer MS Teams channel configuration ARN (null when ENABLE_CHATBOT = false)"
  value       = try(awscc_chatbot_microsoft_teams_channel_configuration.pipeline[0].id, null)
}

output "pipeline_trigger_cli_command" {
  description = "CLI command template to manually trigger the pipeline — replace MODULE_PATH with the actual module path"
  value       = <<EOT

# ── Trigger pipeline (replace MODULE_PATH value as needed) ────────
aws codepipeline start-pipeline-execution \
  --name ${aws_codepipeline.terraform.name} \
  --variables name=MODULE_PATH,value=<environment-deployments/dev/dev-s3>
EOT
}
