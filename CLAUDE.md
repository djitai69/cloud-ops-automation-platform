# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Terraform-based cloud operations automation platform targeting AWS (`eu-central-1`). The goal is automated deployment, monitoring, and infrastructure management across dev and prod environments.

## Common Commands

All Terraform commands run from within the relevant directory (`terraform/bootstrap/` or `terraform/environments/dev/`).

```bash
# Format check (also run by CI)
terraform fmt -check -recursive

# Auto-fix formatting
terraform fmt -recursive

# Validate configuration
terraform init && terraform validate

# Plan / apply
terraform plan
terraform apply
```

CI runs `terraform init`, `terraform fmt -check -recursive`, and `terraform validate` against `terraform/environments/dev` on every push/PR to `main`.

## Architecture

### State Management (bootstrap)

`terraform/bootstrap/` is a one-time setup that must be applied first. It creates:
- S3 bucket `itai-cloud-ops-tf-state` — remote state storage (versioned, AES256 encrypted)
- DynamoDB table `terraform-locks` — state locking (`PAY_PER_REQUEST`)

Bootstrap has its own local state (`terraform/bootstrap/terraform.tfstate`) and is **not** managed by the remote backend it creates.

### Environment Configuration

`terraform/environments/dev/main.tf` uses the S3 backend (`dev/terraform.tfstate`) and wires together the reusable modules. The `dynamodb_table` lock line is commented out in favor of the newer `use_lockfile = true` S3 native locking.

### Modules

`terraform/modules/` contains reusable modules consumed by environments:

- **networking** — VPC (`10.0.0.0/16`), internet gateway, 2 public subnets across `eu-central-1a/b`, and route tables. Private subnet resources are present but commented out, ready to enable.
- **compute** — stub module; accepts `vpc_id` and `subnet_id` from networking outputs.

Modules expose outputs (e.g., `networking.vpc_id`, `networking.public_subnets`) that environments consume directly — no variable threading at the environment level unless customization is needed.

### Adding a New Module

1. Create `terraform/modules/<name>/` with `main.tf`, `variables.tf`, `outputs.tf`.
2. Reference it in `terraform/environments/dev/main.tf` (and future `prod/main.tf`) with `source = "../../modules/<name>"`.
3. Pass required inputs from sibling module outputs.

### AWS Region

Everything targets `eu-central-1`. Availability zones used: `eu-central-1a`, `eu-central-1b`.
