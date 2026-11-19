# ═══════════════════════════════════════════════════════════════
# ASSUME ROLE TRUST POLICIES
# ═══════════════════════════════════════════════════════════════

data "aws_iam_policy_document" "assume_codepipeline" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "assume_codebuild" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "assume_chatbot" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["chatbot.amazonaws.com"]
    }
  }
}

# ═══════════════════════════════════════════════════════════════
# CODEPIPELINE ROLE
# ═══════════════════════════════════════════════════════════════

resource "aws_iam_role" "codepipeline" {
  name               = "${local.name_prefix}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_codepipeline.json

  tags = {
    Name        = "${local.name_prefix}-role"
    Environment = var.ENVIRONMENT
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy" "codepipeline" {
  name   = "${local.name_prefix}-policy"
  role   = aws_iam_role.codepipeline.id
  policy = data.aws_iam_policy_document.codepipeline_policy.json
}

data "aws_iam_policy_document" "codepipeline_policy" {

  statement {
    sid    = "ArtifactBucketAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject", "s3:GetObjectVersion",
      "s3:GetBucketVersioning", "s3:ListBucket",
      "s3:PutObject", "s3:PutObjectAcl",
    ]
    resources = [
      aws_s3_bucket.pipeline.arn,
      "${aws_s3_bucket.pipeline.arn}/*",
    ]
  }

  statement {
    sid       = "KMSAccess"
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:DescribeKey", "kms:Encrypt", "kms:GenerateDataKey*"]
    resources = [aws_kms_key.pipeline.arn]
  }

  statement {
    sid     = "CodeBuildAccess"
    effect  = "Allow"
    actions = ["codebuild:BatchGetBuilds", "codebuild:StartBuild", "codebuild:StopBuild"]
    resources = [
      aws_codebuild_project.validate_plan.arn,
      aws_codebuild_project.apply.arn,
    ]
  }

  statement {
    sid       = "CodeStarConnectionUse"
    effect    = "Allow"
    actions   = ["codestar-connections:UseConnection"]
    resources = [var.CODESTAR_CONNECTION_ARN]
  }

}

# ═══════════════════════════════════════════════════════════════
# CODEBUILD ROLE  
# ═══════════════════════════════════════════════════════════════

resource "aws_iam_role" "codebuild" {
  name               = "${local.name_prefix}-codebuild-role"
  assume_role_policy = data.aws_iam_policy_document.assume_codebuild.json

  tags = {
    Name        = "${local.name_prefix}-codebuild-role"
    Environment = var.ENVIRONMENT
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy" "codebuild" {
  name   = "${local.name_prefix}-codebuild-policy"
  role   = aws_iam_role.codebuild.id
  policy = data.aws_iam_policy_document.codebuild_policy.json
}

data "aws_iam_policy_document" "codebuild_policy" {

  statement {
    sid       = "CloudWatchLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:${var.REGION}:${var.ACCOUNT_ID}:log-group:/aws/codebuild/${local.name_prefix}-*"]
  }

  # Read tfvars from existing bucket (env/ prefix only)
  statement {
    sid       = "ReadTfvarsFromExistingBucket"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:GetObjectVersion"]
    resources = ["arn:aws:s3:::${var.EXISTING_S3_BUCKET}/env/*"]
  }

  # Read/write state files in existing bucket (statefile/ prefix)
  statement {
    sid    = "TerraformStateAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject", "s3:GetObjectVersion", "s3:PutObject",
      "s3:DeleteObject", "s3:ListBucket", "s3:GetBucketVersioning",
    ]
    resources = [
      "arn:aws:s3:::${var.EXISTING_S3_BUCKET}",
      "arn:aws:s3:::${var.EXISTING_S3_BUCKET}/statefile/*",
    ]
  }

  # Read/write plans and artifacts in new pipeline bucket
  statement {
    sid     = "PipelineBucketAccess"
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:GetObjectVersion", "s3:PutObject", "s3:ListBucket"]
    resources = [
      aws_s3_bucket.pipeline.arn,
      "${aws_s3_bucket.pipeline.arn}/*",
    ]
  }

  statement {
    sid       = "KMSAccess"
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:DescribeKey", "kms:Encrypt", "kms:GenerateDataKey*", "kms:ReEncrypt*"]
    resources = [aws_kms_key.pipeline.arn]
  }

  # DynamoDB — Terraform state locking (if lock table is used)
  statement {
    sid       = "TerraformStateLocking"
    effect    = "Allow"
    actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem", "dynamodb:DescribeTable"]
    resources = ["arn:aws:dynamodb:${var.REGION}:${var.ACCOUNT_ID}:table/*"]
  }

  # Broad Terraform permissions — Option A (covers all module calls)
  statement {
    sid    = "TerraformBroadPermissions"
    effect = "Allow"
    actions = [
      "ec2:*",
      "iam:GetRole", "iam:GetRolePolicy", "iam:GetPolicy", "iam:GetPolicyVersion",
      "iam:GetUser", "iam:GetGroup", "iam:ListAttachedRolePolicies", "iam:ListRolePolicies",
      "iam:ListPolicies", "iam:CreateRole", "iam:DeleteRole", "iam:AttachRolePolicy",
      "iam:DetachRolePolicy", "iam:PutRolePolicy", "iam:DeleteRolePolicy",
      "iam:PassRole", "iam:TagRole", "iam:UntagRole", "iam:UpdateAssumeRolePolicy",
      "iam:CreatePolicyVersion", "iam:CreatePolicy", "iam:DeletePolicy",
      "guardduty:*", "securityhub:*", "inspector2:*",
      "config:*", "cloudtrail:*", "access-analyzer:*",
      "kms:*", "s3:*", "sns:*",
      "cloudwatch:*", "logs:*", "ssm:*",
      "route53:*", "route53resolver:*", "iam:CreateServiceLinkedRole",
    ]
    resources = ["*"]
  }
}

# ═══════════════════════════════════════════════════════════════
# CHATBOT ROLE  (Amazon Q Developer — MS Teams notifications)
# ═══════════════════════════════════════════════════════════════

resource "aws_iam_role" "chatbot" {
  name               = "${local.name_prefix}-chatbot-role"
  assume_role_policy = data.aws_iam_policy_document.assume_chatbot.json

  tags = {
    Name        = "${local.name_prefix}-chatbot-role"
    Environment = var.ENVIRONMENT
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy" "chatbot" {
  name   = "${local.name_prefix}-chatbot-policy"
  role   = aws_iam_role.chatbot.id
  policy = data.aws_iam_policy_document.chatbot_policy.json
}

data "aws_iam_policy_document" "chatbot_policy" {
  statement {
    sid    = "CloudWatchReadForChatbot"
    effect = "Allow"
    actions = [
      "cloudwatch:Describe*", "cloudwatch:Get*", "cloudwatch:List*",
      "logs:Describe*", "logs:Get*", "logs:List*",
      "logs:StartQuery", "logs:StopQuery",
      "logs:TestMetricFilter", "logs:FilterLogEvents",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "SNSTopicRead"
    effect    = "Allow"
    actions   = ["sns:ListSubscriptionsByTopic", "sns:GetTopicAttributes"]
    resources = [aws_sns_topic.pipeline_notifications.arn]
  }
}

