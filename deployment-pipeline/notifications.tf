# ─────────────────────────────────────────────────────────────────
# CodeStar Notification Rule — Pipeline → SNS → Chatbot → MS Teams
#
# This is the NATIVE way to send CodePipeline events to Chatbot.
# No EventBridge rules needed. The notification rule attaches
# directly to the pipeline ARN and publishes to the SNS topic
# that Chatbot subscribes to.
#
# Flow:
#   CodePipeline state change
#     → CodeStar Notification Rule
#       → SNS topic (pipeline_notifications)
#         → Amazon Q Developer (Chatbot)
#           → MS Teams channel
#
# Events captured:
#   Pipeline level : started, succeeded, failed, canceled
#   Approval       : needed
# ─────────────────────────────────────────────────────────────────

resource "aws_codestarnotifications_notification_rule" "pipeline" {
  name        = "${local.name_prefix}-notifications"
  resource    = aws_codepipeline.terraform.arn
  detail_type = "BASIC"

  event_type_ids = [
    "codepipeline-pipeline-pipeline-execution-started",
    "codepipeline-pipeline-pipeline-execution-succeeded",
    "codepipeline-pipeline-pipeline-execution-failed",
    "codepipeline-pipeline-pipeline-execution-canceled",
    "codepipeline-pipeline-manual-approval-needed",
  ]

  target {
    type    = "SNS"
    address = aws_sns_topic.pipeline_notifications.arn
  }

  tags = {
    Name        = "${local.name_prefix}-notifications"
    Environment = var.ENVIRONMENT
    ManagedBy   = "terraform"
  }
}
