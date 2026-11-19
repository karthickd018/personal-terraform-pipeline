# ─────────────────────────────────────────────────────────────────
# CloudWatch Log Groups — pre-created so retention is enforced
# ─────────────────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "validate_plan" {
  name              = "/aws/codebuild/${local.name_prefix}-validate-plan"
  retention_in_days = 30
  kms_key_id        = var.CLOUDWATCH_ENCRYPTION_ENABLED ? aws_kms_key.pipeline.arn : null

  tags = {
    Name        = "${local.name_prefix}-validate-plan"
    Environment = var.ENVIRONMENT
    ManagedBy   = "terraform"
  }
}

resource "aws_cloudwatch_log_group" "apply" {
  name              = "/aws/codebuild/${local.name_prefix}-apply"
  retention_in_days = 30
  kms_key_id        = var.CLOUDWATCH_ENCRYPTION_ENABLED ? aws_kms_key.pipeline.arn : null

  tags = {
    Name        = "${local.name_prefix}-apply"
    Environment = var.ENVIRONMENT
    ManagedBy   = "terraform"
  }
}

# ─────────────────────────────────────────────────────────────────
# CodeBuild Project 1 — Validate + Plan
# Runs: fmt check → validate → checkov → terraform plan
# Uploads tfplan binary to s3://pipeline-bucket/plans/<MODULE_PATH>/<EXEC_ID>/
# ─────────────────────────────────────────────────────────────────

resource "aws_codebuild_project" "validate_plan" {
  name          = "${local.name_prefix}-validate-plan"
  description   = "Runs terraform fmt, validate, checkov scan, and plan. Saves tfplan to S3."
  build_timeout = 30
  service_role  = aws_iam_role.codebuild.arn

  tags = {
    Name        = "${local.name_prefix}-validate-plan"
    Environment = var.ENVIRONMENT
    ManagedBy   = "terraform"
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  source {
    type = "CODEPIPELINE"
    # Buildspec lives in the repo under deployment-pipeline/buildspec/
    buildspec = "deployment-pipeline/buildspec/buildspec-plan.yml"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "EXISTING_BUCKET"
      value = var.EXISTING_S3_BUCKET
    }

    environment_variable {
      name  = "PIPELINE_BUCKET"
      value = local.pipeline_bucket_name
    }

    environment_variable {
      name  = "TF_VERSION"
      value = var.TERRAFORM_VERSION
    }

    environment_variable {
      name  = "CHECKOV_VERSION"
      value = var.CHECKOV_VERSION
    }

    environment_variable {
      name  = "COMMON_NAME"
      value = var.COMMON_NAME
    }

    environment_variable {
      name  = "ENVIRONMENT"
      value = var.ENVIRONMENT
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = var.ACCOUNT_ID
    }

    environment_variable {
      name  = "ENABLE_CHECKOV"
      value = tostring(var.ENABLE_CHECKOV)
    }

    environment_variable {
      name  = "CHECKOV_HARD_FAIL"
      value = tostring(var.CHECKOV_HARD_FAIL)
    }

    environment_variable {
      name  = "ENABLE_TF_FMT"
      value = tostring(var.ENABLE_TF_FMT)
    }

    # MODULE_PATH and PIPELINE_EXECUTION_ID injected per-run by CodePipeline action
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.validate_plan.name
      stream_name = "build"
    }
  }

  encryption_key = aws_kms_key.pipeline.arn
}

# ─────────────────────────────────────────────────────────────────
# CodeBuild Project 2 — Apply
# Downloads the EXACT tfplan saved by the plan stage (same execution ID).
# Never re-plans. Applies only what was reviewed and approved.
# ─────────────────────────────────────────────────────────────────

resource "aws_codebuild_project" "apply" {
  name          = "${local.name_prefix}-apply"
  description   = "Downloads approved tfplan from S3 and runs terraform apply."
  build_timeout = 60
  service_role  = aws_iam_role.codebuild.arn

  tags = {
    Name        = "${local.name_prefix}-apply"
    Environment = var.ENVIRONMENT
    ManagedBy   = "terraform"
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "deployment-pipeline/buildspec/buildspec-apply.yml"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "PIPELINE_BUCKET"
      value = local.pipeline_bucket_name
    }

    environment_variable {
      name  = "TF_VERSION"
      value = var.TERRAFORM_VERSION
    }

    environment_variable {
      name  = "EXISTING_BUCKET"
      value = var.EXISTING_S3_BUCKET
    }

    # MODULE_PATH and PIPELINE_EXECUTION_ID injected per-run
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.apply.name
      stream_name = "build"
    }
  }

  encryption_key = aws_kms_key.pipeline.arn
}
