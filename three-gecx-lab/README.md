# Three GECX Lab — Step-by-Step Setup

Replicates the 3IR GECX landing-zone pattern in a personal GCP org
(`bhardwaj-anil00007-org`), using Cloud Identity as IdP and a personal
GitHub repo + GitHub Actions as the pipeline. Everything the pipeline does
mirrors the real design: stage-scoped Terraform service accounts, Workload
Identity Federation (zero SA keys), plan-on-PR / apply-on-main.

## 3IR → Lab substitutions

| 3IR component | Lab substitute | Why |
|---|---|---|
| THREE existing org, inherited policies | You own the org → you build the org policies yourself (stage 1) | Bonus learning: you get to do THREE's side too |
| Three SSO Platform (SAML) | Cloud Identity Free users/groups | Free |
| Dedicated Interconnect to 3 DCs | A second "hub" VPC simulating THREE's Networking project (stage 2); no Interconnect/VPN | Interconnect ≈ €€€€; VPN ≈ ~$36/mo |
| NCC hub in NCC-HUB project | NCC hub in the lab hub project (VPC spokes) — or VPC Peering if you want zero risk of spoke charges | Same topology |
| Cloud NAT in THREE's Networking project | Cloud NAT in lab hub project — **create only while testing, destroy after** (~$0.045/hr + data) | Cost |
| Apigee | Skip (or API Gateway later) | Apigee eval ≠ free tier friendly |
| GECX / CX Agent Studio | A Cloud Run "tool adapter" hello-service (stage 4); optionally Dialogflow CX trial | GECX not available on personal accounts |
| dev / preprod / prod | dev / prod | Project quota + cost |
| BMC Helix ITSM, SCC Premium | Skip / SCC Standard (free) | Cost |

**Budget guardrail first:** create a budget on your billing account (Billing → Budgets & alerts) at e.g. €5 with 50/90/100% email alerts before you build anything.

---

## Step 0 — Prerequisites (once, ~30 min)

1. Install tooling locally: `gcloud` CLI, Terraform ≥ 1.7, git.
2. Log in and confirm the org and billing account:r
   ```bash
   gcloud auth login
   gcloud organizations list
   #  ORG_ID (numeric) for bhardwaj-anil00007-org → note it
   gcloud billing accounts list
   #  ACCOUNT_ID XXXXXX-XXXXXX-XXXXXX → note it
   ```
3. Confirm your account has the needed org-level roles (as org creator you're usually Org Admin already):
   ```bash
   gcloud organizations get-iam-policy ORG_ID \
     --flatten="bindings[].members" \
     --filter="bindings.members:user:YOUR_EMAIL" \
     --format="value(bindings.role)"
   ```
   You need (grant to yourself in console → IAM at org level if missing):
   `roles/resourcemanager.organizationAdmin`, `roles/resourcemanager.folderAdmin`,
   `roles/resourcemanager.projectCreator`, `roles/billing.admin`,
   `roles/iam.workloadIdentityPoolAdmin`, `roles/orgpolicy.policyAdmin`.
4. Create groups in admin.google.com → Directory → Groups (mirrors the 3IR group model; optional for a solo lab but do it for fidelity):
   `grp-gecx-platform-admins`, `grp-gecx-developers`, `grp-gecx-operations` — add yourself.
5. Application Default Credentials for Terraform:
   ```bash
   gcloud auth application-default login
   ```

## Step 1 — Bootstrap (local, once)

Creates `fldr-gecx`, the `*-gecx-cicd` project, state bucket, two stage
service accounts, and the WIF pool for GitHub Actions.

```bash
cd 0-bootstrap
cp terraform.tfvars.example terraform.tfvars   # fill org_id, billing, prefix, github_repository
terraform init
terraform plan
terraform apply
```

Gotchas:
- **Prefix must make project IDs globally unique** — if `apply` fails with "project ID already exists", change the prefix.
- If org-level calls fail with quota-project errors, re-run after:
  `gcloud auth application-default set-quota-project <PREFIX>-gecx-cicd`
  (project exists after first partial apply) or set `quota_project_id` in tfvars.

Migrate state into the bucket:
1. Uncomment the `backend "gcs"` block in `0-bootstrap/versions.tf`, set the bucket name from output `state_bucket`.
2. `terraform init -migrate-state` → answer `yes`.

Record the outputs — you need them in Step 2:
```bash
terraform output
```

## Step 2 — GitHub repo + Actions wiring

1. Create a **private** repo `three-gecx-lab` under your GitHub account, push this scaffold:
   ```bash
   git init && git add -A && git commit -m "bootstrap + foundation scaffold"
   git branch -M main
   git remote add origin git@github.com:<you>/three-gecx-lab.git
   git push -u origin main
   ```
2. Repo → Settings → Secrets and variables → Actions → **Variables** (not secrets — none of these are secret):

   | Variable | Value (from bootstrap outputs) |
   |---|---|
   | `GCP_WIF_PROVIDER` | `wif_provider` output |
   | `SA_TF_FOUNDATION` | `sa_tf_foundation` output |
   | `SA_TF_WORKLOADS` | `sa_tf_workloads` output |
   | `TF_STATE_BUCKET` | `state_bucket` output |
   | `GCP_ORG_ID` | numeric org id |
   | `GCP_BILLING_ID` | billing account id |
   | `LAB_PREFIX` | same prefix as bootstrap |
   | `GECX_FOLDER_ID` | `gecx_folder_id` output (`folders/123…`) |
   | `CICD_PROJECT_ID` | `cicd_project_id` output |

3. **Prod approval gate caveat:** GitHub *environment protection rules* (required reviewers)
   are not available on private repos under the Free plan. Options: make the repo public,
   or accept auto-apply on `main` and enforce review via branch protection
   (Settings → Branches → require PR before merging — this IS available on Free
   for public repos; on private Free repos, rely on discipline / CODEOWNERS).
   In 3IR this gate is a hard requirement; in the lab, note the gap and move on.

## Step 3 — Foundation via the pipeline (folders, projects, org policies)

1. Create a branch, touch something trivial in `1-foundation/` (or just open a PR with the scaffold), and open a PR → the workflow runs **fmt/validate/plan**. Read the plan in the Actions log.
2. Merge to `main` → **apply** runs. Verify:
   ```bash
   gcloud resource-manager folders list --organization=ORG_ID
   gcloud projects list --filter="parent.type=folder"
   gcloud org-policies list --organization=ORG_ID
   ```
3. What you just built = THREE's inherited posture from the design doc:
   env folders, `<prefix>-gecx-dev` / `<prefix>-gecx-prod` projects, SA-key bans,
   no default networks, no external IPs, EU-only locations, uniform bucket access,
   org audit-log sink.

   ⚠️ Leave `iam.allowedPolicyMemberDomains` commented until everything else works —
   misconfiguring it can lock you out of your own org.

## Step 4 — Network stage (next session)

`2-network/` will add, all inside the lab:
- `prj-gecx-net-hub` project + `vpc-hub` — simulating THREE's Networking project
- NCC hub + `vpc-gecx-{env}` spokes in the workload projects (or VPC peering, zero-cost option)
- Subnets, Private Google Access, Cloud DNS private zone for `googleapis.com`
- Network firewall policy: default-deny egress + allows per the 3IR table
- Cloud NAT in the hub — **apply, test, destroy** to keep cost ≈ €0

## Step 5 — Security stage

`3-security/`: KMS keyring/key per env (~$0.06/key/mo), Secret Manager shells,
Data Access audit logs on Storage/Secret Manager, budget alert as code.

## Step 6 — Workload skeleton

`4-workload/`: one Cloud Run service per env acting as the "tool adapter"
(internal ingress, dedicated SA `sa-tool-demo-{env}`, invoker binding —
implements the SAD's per-tool permission model in miniature), a GCS bucket
with CMEK, and a smoke test hitting it through the spoke.

## Teardown

Reverse order: `terraform destroy` in 4 → 3 → 2 → 1, then bootstrap locally.
Projects use `deletion_policy = "DELETE"` so destroy actually removes them
(they sit in 30-day pending-delete; billing stops for most services immediately,
but delete NAT/addresses explicitly first if you created any).

## Cost expectations

Foundation + IAM + WIF + org policies + empty projects + log sink: effectively €0
(log storage pennies, 30-day lifecycle). The only meaningful hourly items in the
whole lab are Cloud NAT and (if chosen) NCC spokes — both in stage 4/2 and both
destroyable between sessions.
