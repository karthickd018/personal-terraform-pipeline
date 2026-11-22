# ─────────────────────────────────────────────
# General
# ─────────────────────────────────────────────

variable "COMMON_NAME" {
  description = "Short project prefix used in all resource names"
  type        = string
}

variable "ENVIRONMENT" {
  description = "Environment tag applied to all resources"
  type        = string
}

variable "REGION" {
  description = "AWS region for all resources"
  type        = string
}

variable "ACCOUNT_ID" {
  description = "AWS account ID"
  type        = string
}

# ─────────────────────────────────────────────
# Existing S3 bucket  (state + env tfvars)
# ─────────────────────────────────────────────

variable "EXISTING_S3_BUCKET" {
  description = <<EOT
Pre-existing S3 bucket name used for:
  State files  → <bucket>/statefile/<module>/terraform.tfstate
  tfvars files → <bucket>/env/<module-name>.tfvars
EOT
  type        = string
}

# ─────────────────────────────────────────────
# New pipeline S3 bucket  (artifacts + plans)
# ─────────────────────────────────────────────


# ─────────────────────────────────────────────
# GitHub / CodeStar
# ─────────────────────────────────────────────

variable "CODESTAR_CONNECTION_ARN" {
  description = "ARN of the manually-created CodeStar Connection for GitHub. Create in AWS Console → CodePipeline → Settings → Connections, then paste the ARN here."
  type        = string
}

variable "GITHUB_REPO_ID" {
  description = "GitHub repo in the format owner/repo-name  e.g. myorg/CC-Terraform"
  type        = string
}

variable "GITHUB_BRANCH" {
  description = "Branch to track in the pipeline Source stage"
  type        = string
  default     = "main"
}

# ─────────────────────────────────────────────
# GitHub Actions CI / CD (OIDC)
# ─────────────────────────────────────────────

variable "ENABLE_GITHUB_ACTIONS_CI" {
  description = "Create IAM roles for GitHub Actions: PR terraform plan (CI) and controlled CodePipeline start (CD)."
  type        = bool
  default     = true
}

variable "GITHUB_OIDC_PROVIDER_ARN" {
  description = <<EOT
Existing GitHub OIDC provider ARN in this account (iam::oidc-provider/token.actions.githubusercontent.com).
Leave empty to create a new provider. Set this if the account already has one (only one provider URL is allowed).
EOT
  type        = string
  default     = ""
}

# ─────────────────────────────────────────────
# Tooling versions — pin for reproducibility
# ─────────────────────────────────────────────

variable "TERRAFORM_VERSION" {
  description = "Terraform version installed inside CodeBuild"
  type        = string
  default     = "1.9.8"
}

variable "CHECKOV_VERSION" {
  description = "Checkov version installed inside CodeBuild"
  type        = string
  default     = "3.2.0"
}

# ─────────────────────────────────────────────
# Plan stage feature toggles
# ─────────────────────────────────────────────

variable "ENABLE_CHECKOV" {
  description = "Install and run Checkov security scan in the plan stage"
  type        = bool
  default     = true
}

variable "CHECKOV_HARD_FAIL" {
  description = "Fail the plan stage if Checkov reports any findings (false = warn only)"
  type        = bool
  default     = false
}

variable "ENABLE_TF_FMT" {
  description = "Run terraform fmt -check in the plan stage"
  type        = bool
  default     = true
}

# ─────────────────────────────────────────────
# MS Teams — Amazon Q Developer (AWS Chatbot)
# Optional for personal accounts — set ENABLE_CHATBOT = true after Teams auth.
# ─────────────────────────────────────────────

variable "ENABLE_CHATBOT" {
  description = "Create AWS Chatbot Microsoft Teams channel configuration. Leave false for personal accounts without Teams."
  type        = bool
  default     = false
}

variable "TEAMS_WORKSPACE_ID" {
  description = <<EOT
MS Teams Team ID (not the channel). Find this by:
  1. Open Teams → right-click on the team → Get link to team
  2. Extract the groupId from the URL
OR via AWS Console after authorising the Chatbot Teams workspace.
Required only when ENABLE_CHATBOT = true.
EOT
  type        = string
  default     = ""
}

variable "TEAMS_CHANNEL_ID" {
  description = <<EOT
MS Teams channel ID. Find this by:
  1. Open Teams → right-click on the channel → Get link to channel
  2. The channel ID is the threadId value in the URL (URL-encoded)
Required only when ENABLE_CHATBOT = true.
EOT
  type        = string
  default     = ""
}

variable "TEAMS_TENANT_ID" {
  description = "Azure AD Tenant ID for your MS Teams organisation. Required only when ENABLE_CHATBOT = true."
  type        = string
  default     = ""
}

# ─────────────────────────────────────────────
# KMS key admins
# ─────────────────────────────────────────────

# ─────────────────────────────────────────────
# SNS / CloudWatch encryption toggles
# ─────────────────────────────────────────────

variable "SNS_ENCRYPTION_ENABLED" {
  description = "Encrypt both SNS topics (approval + notifications) with the pipeline KMS CMK"
  type        = bool
  default     = true
}

variable "CLOUDWATCH_ENCRYPTION_ENABLED" {
  description = "Encrypt both CodeBuild CloudWatch log groups with the pipeline KMS CMK"
  type        = bool
  default     = true
}

# ─────────────────────────────────────────────
# Pipeline S3 bucket toggles
# ─────────────────────────────────────────────

variable "S3_VERSIONING_ENABLED" {
  description = "Enable versioning on the pipeline S3 bucket"
  type        = bool
  default     = true
}

variable "S3_ENCRYPTION_ENABLED" {
  description = "Enable KMS server-side encryption on the pipeline S3 bucket"
  type        = bool
  default     = true
}

variable "S3_PUBLIC_ACCESS_BLOCK_ENABLED" {
  description = "Block all public access on the pipeline S3 bucket"
  type        = bool
  default     = true
}

variable "S3_ENFORCE_SSL_ONLY" {
  description = "Attach a bucket policy that denies all non-SSL (HTTP) requests"
  type        = bool
  default     = true
}

variable "S3_LIFECYCLE_ENABLED" {
  description = "Enable lifecycle rules to expire old plans and artifacts"
  type        = bool
  default     = true
}
