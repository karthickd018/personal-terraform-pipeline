# Account / Project Configuration Sheet

Template reuse checklist for any project / AWS account.

## Current account values (filled)

| # | Variable | Your value | Where applied |
|---|---|---|---|
| 1 | `COMMON_NAME` | `personal` | `deployment-pipeline/example.tfvars`, `terraform.tfvars` |
| 2 | `ENVIRONMENT` | `staging` | same |
| 3 | `REGION` | `ap-south-1` | tfvars + all `state.tf` |
| 4 | `ACCOUNT_ID` | `599524094747` | tfvars |
| 5 | `EXISTING_S3_BUCKET` | `staging-terraform-tfstate-bucket` *(name only, not ARN)* | tfvars + all `state.tf` |
| 6 | `CODESTAR_CONNECTION_ARN` | `arn:aws:codestar-connections:ap-south-1:599524094747:connection/0a729da0-c4b4-4a0d-a48f-d812c3b00de9` | tfvars |
| 7 | `GITHUB_REPO_ID` | `karthickd018/personal-terraform-pipeline` | tfvars |
| 8 | `GITHUB_BRANCH` | `main` | tfvars |
| 9 | `ENABLE_CHATBOT` | `false` | tfvars |

### `state.tf` files updated (same bucket + region)

| File | State key |
|---|---|
| `deployment-pipeline/state.tf` | `statefile/deployment-pipeline/terraform.tfstate` |
| `environment-deployments/dev/dev-s3/state.tf` | `statefile/environment-deployments/dev/dev-s3/terraform.tfstate` |
| `environment-deployments/dev/dev-ec2/state.tf` | `statefile/environment-deployments/dev/dev-ec2/terraform.tfstate` |
| `environment-deployments/prod/prod-s3/state.tf` | `statefile/environment-deployments/prod/prod-s3/terraform.tfstate` |
| `environment-deployments/prod/prod-ec2/state.tf` | `statefile/environment-deployments/prod/prod-ec2/terraform.tfstate` |

### Module example tfvars (still need upload to S3 before module deploy)

| Local file | Upload to | Status |
|---|---|---|
| `examples/env/dev-s3.tfvars` | `s3://staging-terraform-tfstate-bucket/env/dev-s3.tfvars` | bucket name set; upload when ready |
| `examples/env/prod-s3.tfvars` | `s3://staging-terraform-tfstate-bucket/env/prod-s3.tfvars` | bucket name set; upload when ready |
| `examples/env/dev-ec2.tfvars` | `s3://staging-terraform-tfstate-bucket/env/dev-ec2.tfvars` | **AMI still needed** |
| `examples/env/prod-ec2.tfvars` | `s3://staging-terraform-tfstate-bucket/env/prod-ec2.tfvars` | **AMI still needed** |

---

## Still optional / later

| Item | Needed for | Notes |
|---|---|---|
| EC2 `ami_id` (ap-south-1) | First EC2 deploy | Not needed to create the pipeline |
| Upload `env/*.tfvars` to S3 | First module deploy via pipeline | Not needed for pipeline bootstrap |
| Push code to GitHub | Pipeline Source stage | Repo: `karthickd018/personal-terraform-pipeline` |
| Confirm bucket has `env/` + `statefile/` prefixes | State + tfvars | Create empty prefixes if missing |
| Chatbot / Teams IDs | Notifications to Teams | Skipped (`ENABLE_CHATBOT=false`) |

---

## Blank sheet for next project / account

| # | Variable | Description | Your value | Where to change |
|---|---|---|---|---|
| 1 | `COMMON_NAME` | Project prefix | | `deployment-pipeline/terraform.tfvars` |
| 2 | `ENVIRONMENT` | Pipeline env tag | | same |
| 3 | `REGION` | AWS region | | tfvars + all `state.tf` |
| 4 | `ACCOUNT_ID` | 12-digit account ID | | tfvars |
| 5 | `EXISTING_S3_BUCKET` | State/tfvars bucket **name** (not ARN) | | tfvars + all `state.tf` |
| 6 | `CODESTAR_CONNECTION_ARN` | Connection ARN (Available) | | tfvars |
| 7 | `GITHUB_REPO_ID` | `owner/repo` | | tfvars |
| 8 | `GITHUB_BRANCH` | Branch | `main` | tfvars |
| 9 | `ENABLE_CHATBOT` | Teams chatbot | `false` | tfvars |

---

## MODULE_PATH quick reference

| Deploy target | MODULE_PATH |
|---|---|
| Dev S3 | `environment-deployments/dev/dev-s3` |
| Dev EC2 | `environment-deployments/dev/dev-ec2` |
| Prod S3 | `environment-deployments/prod/prod-s3` |
| Prod EC2 | `environment-deployments/prod/prod-ec2` |

Pipeline name after apply: `personal-staging-deployment-pipeline`
