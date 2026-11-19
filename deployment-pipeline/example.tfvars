# Copy to terraform.tfvars (gitignored) and fill in real values.
# Then: cd deployment-pipeline && terraform init && terraform apply

COMMON_NAME = "personal"
ENVIRONMENT = "dev"
REGION      = "ap-south-1"
ACCOUNT_ID  = "123456789012"

# Pre-created bucket for state files + env/*.tfvars
EXISTING_S3_BUCKET = "personal-tf-state-123456789012-ap-south-1"

# CodeStar Connection ARN (must be Available)
CODESTAR_CONNECTION_ARN = "arn:aws:codeconnections:ap-south-1:123456789012:connection/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

GITHUB_REPO_ID = "your-github-user/personal-terraform-pipeline"
GITHUB_BRANCH  = "main"

TERRAFORM_VERSION = "1.9.8"
ENABLE_CHECKOV    = true
CHECKOV_HARD_FAIL = false
ENABLE_TF_FMT     = true

# Keep false until Microsoft Teams Chatbot is authorised
ENABLE_CHATBOT    = false
TEAMS_WORKSPACE_ID = ""
TEAMS_CHANNEL_ID   = ""
TEAMS_TENANT_ID    = ""
