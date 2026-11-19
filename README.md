# personal-terraform-pipeline

Reusable **multi-module Terraform deployment pipeline template**.

| Staging (`cc-terraform-staging`) | This template |
|---|---|
| `module-def/` | `reusable-modules/` |
| `module-call/` | `environment-deployments/` |
| `terraform-apply-pipeline/` | `deployment-pipeline/` |

Independent from `terraform-pipeline-template`.

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

Full mapping: **[ACCOUNT_CONFIG.md](./ACCOUNT_CONFIG.md)**

---

## Changes applied from your values

1. Wrote `deployment-pipeline/example.tfvars` and `deployment-pipeline/terraform.tfvars`
2. Set all `state.tf` backends to bucket `staging-terraform-tfstate-bucket` / region `ap-south-1`
3. Converted your S3 ARN → bucket **name** (`staging-terraform-tfstate-bucket`)
4. Filled S3 module example bucket names with account id suffix
5. Left EC2 AMI as placeholder until you provide one
6. Updated `ACCOUNT_CONFIG.md` with filled values + blank sheet for next account

---

## What is enough vs still needed

| Goal | Enough with current values? | Still needed |
|---|---|---|
| Bootstrap / apply `deployment-pipeline` | **Yes** | Push this folder to GitHub; ensure CodeStar connection is Available |
| Deploy `dev-s3` via pipeline | Almost | Upload `examples/env/dev-s3.tfvars` to S3 `env/dev-s3.tfvars` |
| Deploy EC2 via pipeline | No | Provide `ami_id` for `ap-south-1`, then upload EC2 tfvars |

---

## Next steps

1. Push this folder to `karthickd018/personal-terraform-pipeline` (`main`)
2. Confirm S3 bucket exists and has prefixes `env/` and `statefile/`
3. Apply pipeline:

```bash
cd deployment-pipeline
terraform init
terraform apply
```

4. Upload first module tfvars (when ready):

```bash
aws s3 cp examples/env/dev-s3.tfvars \
  s3://staging-terraform-tfstate-bucket/env/dev-s3.tfvars
```

5. Trigger:

```bash
aws codepipeline start-pipeline-execution \
  --name personal-staging-deployment-pipeline \
  --variables name=MODULE_PATH,value=environment-deployments/dev/dev-s3
```

---

## Layout

```
personal-terraform-pipeline/
├── reusable-modules/s3 + ec2
├── environment-deployments/dev + prod
├── deployment-pipeline/
├── examples/env/
├── ACCOUNT_CONFIG.md
└── README.md
```
