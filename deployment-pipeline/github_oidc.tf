# ─────────────────────────────────────────────────────────────────
# GitHub Actions OIDC — CI (PR plan) + controlled deploy trigger
#
# CI:  pull_request → assume plan role → terraform plan (no apply)
# CD:  push to main / workflow_dispatch → start CodePipeline
#      (manual Approval stage still required before apply)
# ─────────────────────────────────────────────────────────────────

data "aws_iam_openid_connect_provider" "github" {
  count = var.ENABLE_GITHUB_ACTIONS_CI && var.GITHUB_OIDC_PROVIDER_ARN != "" ? 1 : 0
  arn   = var.GITHUB_OIDC_PROVIDER_ARN
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.ENABLE_GITHUB_ACTIONS_CI && var.GITHUB_OIDC_PROVIDER_ARN == "" ? 1 : 0

  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  # GitHub Actions root CA thumbprints (AWS may still validate in some paths)
  thumbprint_list = [
    "ffffffffffffffffffffffffffffffffffffffff",
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4c7df47e370",
  ]

  tags = {
    Name        = "${local.name_prefix}-github-oidc"
    Environment = var.ENVIRONMENT
    ManagedBy   = "terraform"
  }
}

locals {
  github_oidc_provider_arn = var.ENABLE_GITHUB_ACTIONS_CI ? (
    var.GITHUB_OIDC_PROVIDER_ARN != "" ? data.aws_iam_openid_connect_provider.github[0].arn : aws_iam_openid_connect_provider.github[0].arn
  ) : null

  # GitHub OIDC "sub" formats:
  #   legacy: repo:owner/name:pull_request
  #   new:    repo:owner@OWNER_ID/name@REPO_ID:pull_request
  github_repo      = var.GITHUB_REPO_ID
  github_repo_owner = split("/", var.GITHUB_REPO_ID)[0]
  github_repo_name  = split("/", var.GITHUB_REPO_ID)[1]

  # Trust both claim formats GitHub may emit
  github_sub_pull_like = [
    "repo:${local.github_repo}:*",
    "repo:${local.github_repo_owner}@*/${local.github_repo_name}@*:*",
  ]
  github_sub_main_like = [
    "repo:${local.github_repo}:ref:refs/heads/${var.GITHUB_BRANCH}",
    "repo:${local.github_repo_owner}@*/${local.github_repo_name}@*:ref:refs/heads/${var.GITHUB_BRANCH}",
  ]
}

# ── Plan-only role (PR CI) ───────────────────────────────────────

data "aws_iam_policy_document" "assume_github_plan" {
  count = var.ENABLE_GITHUB_ACTIONS_CI ? 1 : 0

  statement {
    effect = "Allow"
    # TagSession is required by aws-actions/configure-aws-credentials@v4+
    actions = [
      "sts:AssumeRoleWithWebIdentity",
      "sts:TagSession",
    ]

    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Allow any workflow in this repo (PR, push, workflow_dispatch, etc.)
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.github_sub_pull_like
    }
  }
}

resource "aws_iam_role" "github_plan" {
  count = var.ENABLE_GITHUB_ACTIONS_CI ? 1 : 0

  name               = "${local.name_prefix}-gha-plan-role"
  assume_role_policy = data.aws_iam_policy_document.assume_github_plan[0].json

  tags = {
    Name        = "${local.name_prefix}-gha-plan-role"
    Environment = var.ENVIRONMENT
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy" "github_plan" {
  count = var.ENABLE_GITHUB_ACTIONS_CI ? 1 : 0

  name   = "${local.name_prefix}-gha-plan-policy"
  role   = aws_iam_role.github_plan[0].id
  policy = data.aws_iam_policy_document.github_plan[0].json
}

data "aws_iam_policy_document" "github_plan" {
  count = var.ENABLE_GITHUB_ACTIONS_CI ? 1 : 0

  statement {
    sid       = "ReadTfvars"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:GetObjectVersion"]
    resources = ["arn:aws:s3:::${var.EXISTING_S3_BUCKET}/env/*"]
  }

  statement {
    sid    = "TerraformStateReadWriteForPlan"
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

  statement {
    sid       = "StateLocking"
    effect    = "Allow"
    actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem", "dynamodb:DescribeTable"]
    resources = ["arn:aws:dynamodb:${var.REGION}:${var.ACCOUNT_ID}:table/*"]
  }

  # Same broad read/manage set as CodeBuild so plan can refresh state accurately.
  # Apply still only runs inside CodePipeline after manual approval.
  statement {
    sid    = "TerraformPlanPermissions"
    effect = "Allow"
    actions = [
      "ec2:*",
      "iam:GetRole", "iam:GetRolePolicy", "iam:GetPolicy", "iam:GetPolicyVersion",
      "iam:GetUser", "iam:GetGroup", "iam:ListAttachedRolePolicies", "iam:ListRolePolicies",
      "iam:ListPolicies", "iam:PassRole", "iam:TagRole", "iam:UntagRole",
      "guardduty:*", "securityhub:*", "inspector2:*",
      "config:*", "cloudtrail:*", "access-analyzer:*",
      "kms:*", "s3:*", "sns:*",
      "cloudwatch:*", "logs:*", "ssm:*",
      "route53:*", "route53resolver:*",
    ]
    resources = ["*"]
  }
}

# ── Deploy-trigger role (start CodePipeline only) ────────────────

data "aws_iam_policy_document" "assume_github_deploy" {
  count = var.ENABLE_GITHUB_ACTIONS_CI ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity",
      "sts:TagSession",
    ]

    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Only main-branch jobs may start the deploy pipeline
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.github_sub_main_like
    }
  }
}

resource "aws_iam_role" "github_deploy" {
  count = var.ENABLE_GITHUB_ACTIONS_CI ? 1 : 0

  name               = "${local.name_prefix}-gha-deploy-role"
  assume_role_policy = data.aws_iam_policy_document.assume_github_deploy[0].json

  tags = {
    Name        = "${local.name_prefix}-gha-deploy-role"
    Environment = var.ENVIRONMENT
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy" "github_deploy" {
  count = var.ENABLE_GITHUB_ACTIONS_CI ? 1 : 0

  name   = "${local.name_prefix}-gha-deploy-policy"
  role   = aws_iam_role.github_deploy[0].id
  policy = data.aws_iam_policy_document.github_deploy[0].json
}

data "aws_iam_policy_document" "github_deploy" {
  count = var.ENABLE_GITHUB_ACTIONS_CI ? 1 : 0

  statement {
    sid    = "StartControlledPipeline"
    effect = "Allow"
    actions = [
      "codepipeline:StartPipelineExecution",
      "codepipeline:GetPipeline",
      "codepipeline:GetPipelineExecution",
      "codepipeline:GetPipelineState",
      "codepipeline:ListPipelineExecutions",
    ]
    resources = [aws_codepipeline.terraform.arn]
  }
}
