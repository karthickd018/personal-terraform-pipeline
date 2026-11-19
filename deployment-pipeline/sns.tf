# ─────────────────────────────────────────────────────────────────
# SNS Topic — Pipeline Notifications (MS Teams via Chatbot)
#
# Publisher  : CodeStar Notification Rule  (notifications.tf)
#              Uses the codestar-notifications.amazonaws.com service principal.
#              NO EventBridge involved.
#
# Subscriber : Amazon Q Developer (Chatbot)  →  MS Teams channel  (chatbot.tf)
# ─────────────────────────────────────────────────────────────────

resource "aws_sns_topic" "pipeline_notifications" {
  name              = "${local.name_prefix}-notifications"
  kms_master_key_id = var.SNS_ENCRYPTION_ENABLED ? aws_kms_key.pipeline.arn : null

  tags = {
    Name        = "${local.name_prefix}-notifications"
    Environment = var.ENVIRONMENT
    ManagedBy   = "terraform"
  }
}

resource "aws_sns_topic_policy" "pipeline_notifications" {
  arn = aws_sns_topic.pipeline_notifications.arn
  policy = jsonencode({
    Version = "2008-10-17"
    Statement = [
      {
        Sid    = "CodeNotification_publish"
        Effect = "Allow"
        Principal = {
          Service = [
            "codestar-notifications.amazonaws.com",
            "chatbot.amazonaws.com"
          ]
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.pipeline_notifications.arn
      }
    ]
  })
}