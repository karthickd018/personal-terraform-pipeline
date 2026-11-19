# personal-terraform-pipeline

Reusable **multi-module Terraform deployment pipeline template** for any project / AWS account.

Architecture is based on `cc-terraform-staging`, with clearer folder names:

| Staging (`cc-terraform-staging`) | This template |
|---|---|
| `module-def/` | `reusable-modules/` |
| `module-call/` | `environment-deployments/` |
| `terraform-apply-pipeline/` | `deployment-pipeline/` |

This project is **independent** of `terraform-pipeline-template` (the older single-root `TF_TARGETS` pipeline). Keep them separate.

---

## What was scaffolded (current state)

| Area | What exists |
|---|---|
| `reusable-modules/s3` | Reusable S3 module (bucket, public access block, versioning, SSE) |
| `reusable-modules/ec2` | Reusable EC2 module |
| `environment-deployments/dev/dev-s3` | Dev root module that calls S3 |
| `environment-deployments/dev/dev-ec2` | Dev root module that calls EC2 |
| `environment-deployments/prod/prod-s3` | Prod root module that calls S3 |
| `environment-deployments/prod/prod-ec2` | Prod root module that calls EC2 |
| `deployment-pipeline/` | CodePipeline V2 + CodeBuild plan/apply + KMS + SNS (+ optional Chatbot) |
| `examples/env/*.tfvars` | Sample module tfvars to upload to S3 |
| `ACCOUNT_CONFIG.md` | **Master table** of every value to change per account/project |
| Placeholders | All `state.tf` + `example.tfvars` still have `REPLACE-ME` / sample values until you provide real ones |

### Design choices baked into this template

- **MODULE_PATH** selects which root module to deploy (not `TF_TARGETS`)
- Leaf folder names are unique (`dev-s3`, `prod-s3`) so `env/<basename>.tfvars` never collides
- Pipeline is **manual trigger only** (`DetectChanges = false`)
- Chatbot/Teams is **optional** (`ENABLE_CHATBOT = false` by default)
- DynamoDB state locking is **not required** (same as staging backends)

---

## Folder layout

```
personal-terraform-pipeline/
├── reusable-modules/
│   ├── s3/
│   └── ec2/
├── environment-deployments/
│   ├── dev/dev-s3/
│   ├── dev/dev-ec2/
│   ├── prod/prod-s3/
│   └── prod/prod-ec2/
├── deployment-pipeline/
├── examples/env/
├── ACCOUNT_CONFIG.md      ← fill this for every new account/project
└── README.md
```

---

## How to use this as a template for every project/account

1. Open **[ACCOUNT_CONFIG.md](./ACCOUNT_CONFIG.md)**  
2. Fill the **Your value** column (or reply with values so they can be applied in code)  
3. Create the existing S3 bucket + CodeStar connection in that AWS account  
4. Apply `deployment-pipeline/` once  
5. Upload `env/*.tfvars`  
6. Trigger with `MODULE_PATH`

Full variable → file mapping lives only in `ACCOUNT_CONFIG.md` so you can reuse one checklist forever.

---

## Pipeline flow

```
Manual trigger + MODULE_PATH
  → Source (GitHub via CodeStar)
  → Validate-and-Plan (fmt / validate / checkov / plan)
  → Manual Approval
  → Apply (exact saved tfplan)
```

---

## Next step

Provide the values listed in the chat / in `ACCOUNT_CONFIG.md` section A (and optionally B/C).  
Those values will be written into:

- `deployment-pipeline/example.tfvars` (and `terraform.tfvars` if requested)
- all `state.tf` bucket/region fields
- `examples/env/*.tfvars` where applicable
