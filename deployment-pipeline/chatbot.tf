# ─────────────────────────────────────────────────────────────────
# Amazon Q Developer in Chat Applications (AWS Chatbot)
# MS Teams Channel Configuration — OPTIONAL
#
# PRE-REQUISITE when ENABLE_CHATBOT = true:
#   1. AWS Console → Amazon Q Developer → Chat applications
#   2. Configure Microsoft Teams and authorise the workspace
#   3. Set TEAMS_WORKSPACE_ID, TEAMS_CHANNEL_ID, TEAMS_TENANT_ID in tfvars
# ─────────────────────────────────────────────────────────────────

resource "awscc_chatbot_microsoft_teams_channel_configuration" "pipeline" {
  count = var.ENABLE_CHATBOT ? 1 : 0

  configuration_name = "${local.name_prefix}-teams"
  iam_role_arn       = aws_iam_role.chatbot.arn
  team_id            = var.TEAMS_WORKSPACE_ID
  teams_channel_id   = var.TEAMS_CHANNEL_ID
  teams_tenant_id    = var.TEAMS_TENANT_ID
  logging_level      = "INFO"
  sns_topic_arns     = [aws_sns_topic.pipeline_notifications.arn]

  tags = [
    { key = "Name", value = "${local.name_prefix}-teams" },
    { key = "Environment", value = var.ENVIRONMENT },
    { key = "ManagedBy", value = "terraform" },
  ]
}
