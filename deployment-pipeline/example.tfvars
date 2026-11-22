# Copy to terraform.tfvars (gitignored) before apply:
#   cp example.tfvars terraform.tfvars
# Then: cd deployment-pipeline && terraform init && terraform apply

COMMON_NAME = "personal"
ENVIRONMENT = "staging"
REGION      = "ap-south-1"
ACCOUNT_ID  = "599524094747"

# Bucket NAME only (not ARN) — pre-created for state + env/*.tfvars
EXISTING_S3_BUCKET = "staging-terraform-tfstate-bucket"

# CodeStar Connection ARN (must be Available)
CODESTAR_CONNECTION_ARN = "arn:aws:codestar-connections:ap-south-1:599524094747:connection/0a729da0-c4b4-4a0d-a48f-d812c3b00de9"

GITHUB_REPO_ID = "karthickd018/personal-terraform-pipeline"
GITHUB_BRANCH  = "main"

TERRAFORM_VERSION = "1.9.8"
ENABLE_CHECKOV    = true
CHECKOV_HARD_FAIL = false
ENABLE_TF_FMT     = true

ENABLE_CHATBOT     = false
TEAMS_WORKSPACE_ID = ""
TEAMS_CHANNEL_ID   = ""
TEAMS_TENANT_ID    = ""

ENABLE_GITHUB_ACTIONS_CI = true
# Leave empty to create OIDC provider; set ARN if account already has one
GITHUB_OIDC_PROVIDER_ARN = ""
