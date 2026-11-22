# ─────────────────────────────────────────────────────────────────
# Universal Terraform Pipeline (personal-terraform-pipeline)
#
# CI / CD model:
#   CI (automatic)  — GitHub Actions on pull_request runs terraform plan
#                     for changed environment-deployments/* paths only.
#   CD (controlled) — GitHub Actions on push to main / workflow_dispatch
#                     starts THIS pipeline with MODULE_PATH.
#                     Manual Approval stage is still required before apply.
#
# Manual trigger (fallback):
#   Console → Release change → set MODULE_PATH
#   CLI:
#     aws codepipeline start-pipeline-execution \
#       --name <pipeline> \
#       --variables name=MODULE_PATH,value=environment-deployments/dev/dev-s3
# ─────────────────────────────────────────────────────────────────

resource "aws_codepipeline" "terraform" {
  name     = local.name_prefix
  role_arn = aws_iam_role.codepipeline.arn

  # V2 required for pipeline-level variables
  pipeline_type = "V2"

  tags = {
    Name        = local.name_prefix
    Environment = var.ENVIRONMENT
    ManagedBy   = "terraform"
  }

  # Pipeline-level variable — entered at manual trigger time
  variable {
    name          = "MODULE_PATH"
    description   = "Relative path to the environment deployment root to deploy. e.g. environment-deployments/dev/dev-s3"
    default_value = ""
  }

  # Artifact store — new pipeline bucket, KMS encrypted
  artifact_store {
    location = aws_s3_bucket.pipeline.bucket
    type     = "S3"

    encryption_key {
      id   = aws_kms_key.pipeline.arn
      type = "KMS"
    }
  }

  # ══════════════════════════════════════════════════════════════
  # STAGE 1 — Source
  # Pulls the full repo from GitHub.
  # DetectChanges = false → MANUAL TRIGGER ONLY, no auto-push trigger.
  # ══════════════════════════════════════════════════════════════

  stage {
    name = "Source"

    action {
      name             = "GitHubSource"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn        = var.CODESTAR_CONNECTION_ARN
        FullRepositoryId     = var.GITHUB_REPO_ID
        BranchName           = var.GITHUB_BRANCH
        DetectChanges        = "false"
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  # ══════════════════════════════════════════════════════════════
  # STAGE 2 — Validate and Plan
  # fmt check → validate → checkov → terraform plan
  # tfplan saved to S3 keyed by MODULE_PATH + execution ID
  # ══════════════════════════════════════════════════════════════

  stage {
    name = "Validate-and-Plan"

    action {
      name             = "ValidateAndPlan"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["plan_output"]

      configuration = {
        ProjectName = aws_codebuild_project.validate_plan.name

        # Inject MODULE_PATH and execution ID into the CodeBuild environment
        EnvironmentVariables = jsonencode([
          {
            name  = "MODULE_PATH"
            value = "#{variables.MODULE_PATH}"
            type  = "PLAINTEXT"
          },
          {
            name  = "PIPELINE_EXECUTION_ID"
            value = "#{codepipeline.PipelineExecutionId}"
            type  = "PLAINTEXT"
          }
        ])
      }
    }
  }

  # ══════════════════════════════════════════════════════════════
  # STAGE 3 — Approval
  # Manual approval gate — any user with CodePipeline access can approve.
  # ══════════════════════════════════════════════════════════════

  stage {
    name = "Approval"

    action {
      name     = "ReviewAndApprove"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"

      configuration = {
        CustomData = "MODULE: #{variables.MODULE_PATH} | EXEC: #{codepipeline.PipelineExecutionId} | Review the tfplan in S3 before approving: s3://${local.pipeline_bucket_name}/plans/#{variables.MODULE_PATH}/#{codepipeline.PipelineExecutionId}/tfplan.txt"

        ExternalEntityLink = "https://${var.REGION}.console.aws.amazon.com/codesuite/codepipeline/pipelines/${local.name_prefix}/view"
      }
    }
  }

  # ══════════════════════════════════════════════════════════════
  # STAGE 4 — Apply
  # Downloads the EXACT tfplan from S3 using the same execution ID.
  # Applies only what was reviewed and approved — no fresh plan.
  # ══════════════════════════════════════════════════════════════

  stage {
    name = "Apply"

    action {
      name            = "TerraformApply"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source_output"]

      configuration = {
        ProjectName = aws_codebuild_project.apply.name

        EnvironmentVariables = jsonencode([
          {
            name  = "MODULE_PATH"
            value = "#{variables.MODULE_PATH}"
            type  = "PLAINTEXT"
          },
          {
            name  = "PIPELINE_EXECUTION_ID"
            value = "#{codepipeline.PipelineExecutionId}"
            type  = "PLAINTEXT"
          }
        ])
      }
    }
  }
}
