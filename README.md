# personal-terraform-pipeline

Reusable **multi-module Terraform deployment pipeline** with:

- **CI (automatic)** — PR → `terraform plan` for changed paths only  
- **CD (controlled)** — merge / manual dispatch → CodePipeline → **manual approval** → apply  

| Staging (`cc-terraform-staging`) | This template |
|---|---|
| `module-def/` | `reusable-modules/` |
| `module-call/` | `environment-deployments/` |
| `terraform-apply-pipeline/` | `deployment-pipeline/` |

`cc-terraform-staging` is **not** modified by this template.

---

## CI / CD flow

```
Pull Request (environment-deployments/** or reusable-modules/**)
        │
        ▼
 GitHub Actions: PR Terraform Plan     ← automatic CI (plan only)
        │
        ▼
 Merge to main  ──or──  workflow_dispatch (pick MODULE_PATH)
        │
        ▼
 GitHub Actions: Controlled Deploy     ← starts CodePipeline
        │
        ▼
 CodePipeline: Source → Validate/Plan → Approval → Apply
                                      ▲
                                      └── human approval required
```

---

## Current account (applied)

| Setting | Value |
|---|---|
| Account | `599524094747` |
| Region | `ap-south-1` |
| Common name | `personal` |
| Pipeline env | `staging` |
| State/tfvars bucket | `staging-terraform-tfstate-bucket` |
| GitHub | `karthickd018/personal-terraform-pipeline` (`main`) |
| Chatbot | disabled |
| GitHub Actions CI | enabled (OIDC roles) |

Full mapping: **[ACCOUNT_CONFIG.md](./ACCOUNT_CONFIG.md)**

---

## Setup after `terraform apply` (deployment-pipeline)

1. Apply pipeline (creates OIDC roles when `ENABLE_GITHUB_ACTIONS_CI = true`):

```bash
cd deployment-pipeline
terraform init
terraform apply
terraform output github_actions_setup_hint
```

2. In GitHub → **Settings → Secrets and variables → Actions → Variables**, add:

| Variable | Example |
|---|---|
| `AWS_REGION` | `ap-south-1` |
| `AWS_PLAN_ROLE_ARN` | from `github_actions_plan_role_arn` |
| `AWS_DEPLOY_ROLE_ARN` | from `github_actions_deploy_role_arn` |
| `EXISTING_S3_BUCKET` | `staging-terraform-tfstate-bucket` |
| `CODEPIPELINE_NAME` | `personal-staging-deployment-pipeline` |
| `TERRAFORM_VERSION` | `1.9.8` |

3. Upload module tfvars (once per module):

```bash
aws s3 cp examples/env/dev-s3.tfvars \
  s3://staging-terraform-tfstate-bucket/env/dev-s3.tfvars
```

4. Open a PR that changes `environment-deployments/...` → plan runs automatically.  
5. Merge to `main` → CodePipeline starts → **approve** in Console → apply.  
6. Or run **Actions → Controlled Deploy → Run workflow** and set `MODULE_PATH`.

Manual CLI fallback (unchanged):

```bash
aws codepipeline start-pipeline-execution \
  --name personal-staging-deployment-pipeline \
  --variables name=MODULE_PATH,value=environment-deployments/dev/dev-s3
```

---

## Layout

```
personal-terraform-pipeline/
├── .github/workflows/
│   ├── pr-terraform-plan.yml      # CI — PR plan
│   └── controlled-deploy.yml      # CD — start CodePipeline
├── reusable-modules/
├── environment-deployments/
├── deployment-pipeline/
│   ├── github_oidc.tf             # OIDC IAM roles
│   ├── scripts/detect-changed-modules.sh
│   └── ...
├── examples/env/
├── ACCOUNT_CONFIG.md
└── README.md
```
