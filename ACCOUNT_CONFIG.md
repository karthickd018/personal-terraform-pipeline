# Account / Project Configuration Sheet

Use this file every time you reuse this **multi-module Terraform pipeline template** for a new project or AWS account.

Fill the **Your value** column, then apply the same values into the files listed under **Where to change**.

---

## A. Required values (pipeline + backends)

| # | Variable / setting | Description | Example | Your value | Where to change |
|---|---|---|---|---|---|
| 1 | `COMMON_NAME` | Short project prefix used in pipeline / bucket / KMS names | `personal` or `cc` or `acme` | _fill me_ | `deployment-pipeline/example.tfvars` → copy to `terraform.tfvars` |
| 2 | `ENVIRONMENT` | Environment tag for the **pipeline itself** (not module envs) | `dev` | _fill me_ | `deployment-pipeline/terraform.tfvars` |
| 3 | `REGION` | AWS region for pipeline + backends | `ap-south-1` | _fill me_ | `deployment-pipeline/terraform.tfvars` **and** every `state.tf` `region` |
| 4 | `ACCOUNT_ID` | 12-digit AWS account ID | `123456789012` | _fill me_ | `deployment-pipeline/terraform.tfvars` |
| 5 | `EXISTING_S3_BUCKET` | Pre-created S3 bucket for `env/*.tfvars` + `statefile/**` | `personal-tf-state-123456789012-ap-south-1` | _fill me_ | `deployment-pipeline/terraform.tfvars` **and** every `state.tf` `bucket` |
| 6 | `CODESTAR_CONNECTION_ARN` | GitHub CodeStar/CodeConnections ARN (status = Available) | `arn:aws:codeconnections:REGION:ACCOUNT:connection/UUID` | _fill me_ | `deployment-pipeline/terraform.tfvars` |
| 7 | `GITHUB_REPO_ID` | GitHub repo as `owner/repo` | `jeeva/personal-terraform-pipeline` | _fill me_ | `deployment-pipeline/terraform.tfvars` |
| 8 | `GITHUB_BRANCH` | Branch the pipeline Source stage tracks | `main` | _fill me_ | `deployment-pipeline/terraform.tfvars` |

### Files that share the same S3 bucket + region (`state.tf`)

Replace `bucket` and `region` in **all** of these with the same `EXISTING_S3_BUCKET` and `REGION`:

| File | State key (do not change unless you rename folders) |
|---|---|
| `deployment-pipeline/state.tf` | `statefile/deployment-pipeline/terraform.tfstate` |
| `environment-deployments/dev/dev-s3/state.tf` | `statefile/environment-deployments/dev/dev-s3/terraform.tfstate` |
| `environment-deployments/dev/dev-ec2/state.tf` | `statefile/environment-deployments/dev/dev-ec2/terraform.tfstate` |
| `environment-deployments/prod/prod-s3/state.tf` | `statefile/environment-deployments/prod/prod-s3/terraform.tfstate` |
| `environment-deployments/prod/prod-ec2/state.tf` | `statefile/environment-deployments/prod/prod-ec2/terraform.tfstate` |

---

## B. Optional values (Chatbot / Teams)

| # | Variable | Description | Default | Your value | Where to change |
|---|---|---|---|---|---|
| 9 | `ENABLE_CHATBOT` | Create MS Teams Chatbot config | `false` | _fill me_ | `deployment-pipeline/terraform.tfvars` |
| 10 | `TEAMS_WORKSPACE_ID` | MS Teams Team ID | `""` | _fill me_ (only if chatbot on) | `deployment-pipeline/terraform.tfvars` |
| 11 | `TEAMS_CHANNEL_ID` | MS Teams channel ID | `""` | _fill me_ | `deployment-pipeline/terraform.tfvars` |
| 12 | `TEAMS_TENANT_ID` | Azure AD tenant ID | `""` | _fill me_ | `deployment-pipeline/terraform.tfvars` |

---

## C. Module deployment tfvars (uploaded to S3, not git-only)

Upload to: `s3://<EXISTING_S3_BUCKET>/env/<name>.tfvars`

| # | File (local example) | S3 object key | Key fields to set | Your value |
|---|---|---|---|---|
| 13 | `examples/env/dev-s3.tfvars` | `env/dev-s3.tfvars` | `bucket_name`, `region` | _fill me_ |
| 14 | `examples/env/dev-ec2.tfvars` | `env/dev-ec2.tfvars` | `name`, `ami_id`, `instance_type`, `region` | _fill me_ |
| 15 | `examples/env/prod-s3.tfvars` | `env/prod-s3.tfvars` | `bucket_name`, `region` | _fill me_ |
| 16 | `examples/env/prod-ec2.tfvars` | `env/prod-ec2.tfvars` | `name`, `ami_id`, `instance_type`, `region` | _fill me_ |

---

## D. Optional tooling toggles

| # | Variable | Meaning | Suggested default |
|---|---|---|---|
| 17 | `TERRAFORM_VERSION` | Terraform version in CodeBuild | `1.9.8` |
| 18 | `ENABLE_CHECKOV` | Run Checkov in plan | `true` |
| 19 | `CHECKOV_HARD_FAIL` | Fail plan on Checkov findings | `false` |
| 20 | `ENABLE_TF_FMT` | Fail plan if fmt check fails | `true` |

---

## E. Per-account reuse checklist

When cloning this template for a **new project / account**:

1. Copy this repo (or this folder) as a new GitHub repo  
2. Fill section **A** for that account  
3. Update all `state.tf` bucket/region  
4. Create the existing S3 bucket + `env/` + `statefile/` prefixes  
5. Create / reuse CodeStar connection for that account’s GitHub access  
6. `terraform apply` inside `deployment-pipeline/`  
7. Fill section **C** and upload `env/*.tfvars`  
8. Trigger pipeline with `MODULE_PATH` (see README)

---

## F. MODULE_PATH quick reference (after values are set)

| Deploy target | MODULE_PATH value | Needs S3 tfvars |
|---|---|---|
| Dev S3 only | `environment-deployments/dev/dev-s3` | `env/dev-s3.tfvars` |
| Dev EC2 only | `environment-deployments/dev/dev-ec2` | `env/dev-ec2.tfvars` |
| Prod S3 only | `environment-deployments/prod/prod-s3` | `env/prod-s3.tfvars` |
| Prod EC2 only | `environment-deployments/prod/prod-ec2` | `env/prod-ec2.tfvars` |
