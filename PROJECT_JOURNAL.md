# Cloud Ops Automation Platform - Project Journal

## Project Overview

This project aims to build a comprehensive cloud operations automation platform using Infrastructure as Code (IaC) principles with Terraform. The platform will provide automated deployment, monitoring, and management capabilities for cloud infrastructure across multiple environments.

## Project Structure

The project is organized as follows:
- `terraform/bootstrap/`: Initial setup for Terraform state management (S3 bucket and DynamoDB table)
- `terraform/environments/`: Environment-specific configurations (dev, prod)
- `terraform/modules/`: Reusable Terraform modules for IAM, Lambda, monitoring, and networking
- `.github/workflows/`: CI/CD pipelines for automated deployments

## Progress Log

### May 10, 2026 - Project Initialization

**Infrastructure Foundation Setup:**
- Initialized Terraform project with AWS provider (version ~> 5.0)
- Configured S3 bucket (`itai-cloud-ops-tf-state`) for remote Terraform state storage
- Enabled versioning and server-side encryption on the state bucket
- Created DynamoDB table (`terraform-locks`) for state locking with `PAY_PER_REQUEST` billing mode

**Key Technical Decisions:**
- Chose `PAY_PER_REQUEST` billing for DynamoDB lock table due to infrequent Terraform operations
- Set up proper encryption and versioning for state management security and reliability
- Established modular structure to support scalable infrastructure management

**Learning Moments:**
- Deep dive into DynamoDB billing modes: `PAY_PER_REQUEST` vs `PROVISIONED`
- Understanding Terraform state management best practices for team collaboration

### May 14-18, 2026 - Core Modules and Automation

**Modules Built:**
- `networking` — VPC, IGW, 2 public subnets (`eu-central-1a/b`), route tables
- `compute` — EC2 with `amazon-ssm-agent` in user_data, `s3:PutObject` grant on forensics bucket
- `iam`, `monitoring`, `observability` — added; `observability` DynamoDB attribute renamed `status`→`state` (GSI aligned)
- `forensics` — new: versioned S3 bucket for incident reports
- `dashboard` — new: Lambda API + function URL + S3 static site, IAM role, CloudWatch Logs, DynamoDB read access
- `healing` — switched from EC2 reboot to SSM `pkill` + forensics collection; fixed dead return and action label, wired `table_name`/`bucket_name` vars
- `dev` env wired to forensics/dashboard modules, `api_url` output exposed

**Learning Moments:**
- Lambda function URLs with `auth_type=NONE` need BOTH `lambda:InvokeFunctionUrl` AND `lambda:InvokeFunction` resource-based permissions for public access — missing either gives 403.
- CORS: don't set `Access-Control-Allow-Origin` in both the function URL config and app code — duplicate headers break browser CORS.

### May 27, 2026 - CI/CD Pipelines and Hardening

**Pipelines Added:**
- `terraform.yml` — Terraform CI: init/fmt-check/validate/plan against `dev` on push/PR to main
- `dashboard.yml` — dashboard deploy pipeline (Lambda + static frontend)

**Iteration/Fixes (many same-day, tight feedback loop with CI runner failures):**
- Upgraded `actions/checkout` / `aws-actions` to current versions
- Replaced long-lived AWS access keys with GitHub OIDC → short-lived tokens via new `github-oidc` IAM role module
- Pinned EC2 AMI (was resolving latest each plan, causing drift-driven replacement)
- Parameterized EC2 SSH public key as `ssh_public_key` var (was `file("~/.ssh/...")`, unreadable on CI runner); supplied via `EC2_PUBLIC_KEY` secret as `TF_VAR_ssh_public_key`
- Fixed dashboard-ui upload path (assets live at `terraform/dashboard-ui/`, workflow pointed elsewhere); fixed path filter so frontend edits auto-trigger deploy
- tfsec set to soft-fail so scan findings don't block pipeline
- Shared `terraform-dev` concurrency group across both workflows (`cancel-in-progress=false`) — they were racing for the same S3 state lock
- Workflows self-trigger on edits to their own YAML
- Dropped SARIF upload from Terraform CI — code scanning isn't enabled on repo, upload always failed; tfsec findings stay visible in run logs only

**Key Technical Decisions:**
- OIDC over static AWS keys for CI auth (security hardening)
- Concurrency serialization over independent triggers to avoid state-lock races between the two workflows

## Current Status

Foundational infra, core modules (networking, compute, iam, monitoring, observability, forensics, dashboard, healing, github-oidc), and both CI/CD pipelines (Terraform validate + dashboard deploy) are in place and hardened against the failure modes hit during setup (OIDC auth, AMI drift, state-lock races, CORS/permission bugs). Repo scaffold (`docs/`, `.github/` templates) added under `terraform/` on 2026-07-13.

Next steps:
- Resolve/confirm production readiness of Lambda function URL public access (watch for account-level SCP blocking `lambda:InvokeFunctionUrl`)
- Prod environment setup, mirroring `dev` wiring
- Enable private subnets (currently commented out in networking module)

## Future Vision

This platform will serve as a template for automated cloud operations, enabling:
- Rapid deployment across development and production environments
- Automated monitoring and alerting
- Secure access management through IAM
- Scalable networking configurations

---

*This journal will be updated throughout the project lifecycle and will serve as both internal documentation and a comprehensive article for sharing project insights on LinkedIn and other professional platforms.*