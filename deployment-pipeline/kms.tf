resource "aws_kms_key" "pipeline" {
  description             = "${local.name_prefix} artifacts encryption key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  multi_region            = true

  policy = data.aws_iam_policy_document.kms_key_policy.json

  tags = {
    Name        = "${local.name_prefix}-key"
    Environment = var.ENVIRONMENT
    ManagedBy   = "terraform"
  }
}

resource "aws_kms_alias" "pipeline" {
  name          = "alias/${var.COMMON_NAME}-${var.ENVIRONMENT}-deployment-pipeline"
  target_key_id = aws_kms_key.pipeline.key_id
}

data "aws_iam_policy_document" "kms_key_policy" {

  # Root account — required to prevent key lockout
  statement {
    sid    = "RootAccountFullControl"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.ACCOUNT_ID}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  # CodePipeline and CodeBuild service roles — encrypt/decrypt only
  statement {
    sid    = "PipelineServiceRoles"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.codepipeline.arn,
        aws_iam_role.codebuild.arn,
      ]
    }
    actions = [
      "kms:Decrypt", "kms:DescribeKey", "kms:Encrypt",
      "kms:GenerateDataKey*", "kms:ReEncrypt*",
    ]
    resources = ["*"]
  }

  # AWS service principals for cross-service operations
  statement {
    sid    = "AWSServiceIntegration"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com", "codebuild.amazonaws.com", "s3.amazonaws.com"]
    }
    actions = [
      "kms:Decrypt", "kms:DescribeKey", "kms:Encrypt",
      "kms:GenerateDataKey*", "kms:ReEncrypt*",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [var.ACCOUNT_ID]
    }
  }

  # CloudWatch Logs — required for encrypted log groups
  statement {
    sid    = "CloudWatchLogsEncryption"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["logs.${var.REGION}.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*",
      "kms:GenerateDataKey*", "kms:DescribeKey",
    ]
    resources = ["*"]
    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:${var.REGION}:${var.ACCOUNT_ID}:*"]
    }
  }

  # SNS — required for KMS-encrypted topics
  statement {
    sid    = "SNSEncryption"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*",
      "kms:GenerateDataKey*", "kms:DescribeKey",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [var.ACCOUNT_ID]
    }
  }

  # CodeStar Notifications → encrypted SNS topic
  #
  # The KMS call principal is codestar-notifications.amazonaws.com, NOT sns.amazonaws.com.
  # SNS makes the KMS call under the security context of the original caller (CodeStar).
  # kms:ViaService scopes this to only when the request arrives through SNS,
  # preventing CodeStar from using this key directly for any other purpose.
  statement {
    sid    = "AllowCodeStarNotificationsSNSPublish"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codestar-notifications.amazonaws.com"]
    }
    actions = [
      "kms:GenerateDataKey*",
      "kms:Decrypt",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["sns.${var.REGION}.amazonaws.com"]
    }
  }

  # AWS Chatbot service-linked role — decrypt KMS-encrypted SNS messages
  #
  # The correct principal is the SLR ARN, NOT chatbot.amazonaws.com service principal.
  # Chatbot uses its SLR internally to process notifications received from SNS.
  # The chatbot.amazonaws.com service principal has no KMS permissions because it
  # never calls KMS directly — the SLR is what does the decryption.
  statement {
    sid    = "AllowChatbotSLRDecrypt"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.ACCOUNT_ID}:role/aws-service-role/management.chatbot.amazonaws.com/AWSServiceRoleForAWSChatbot"]
    }
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
    ]
    resources = ["*"]
  }

}