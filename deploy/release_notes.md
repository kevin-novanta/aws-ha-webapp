# Release Notes — aws-ha-webapp

Human-readable changelog for each release. Pairs with `VERSION` and CI:

- Push to `main` → image is built & pushed → Terraform plans/applies to **dev**.
- Staging/prod deployments are gated by branch/environment protections.

> Convention: Follow [Keep a Changelog](https://keepachangelog.com/) + SemVer.
> Bump the `VERSION` file with each release.

## [Unreleased]

### Added

- (placeholder)

### Changed

- (placeholder)

### Fixed

- (placeholder)

### Infra

- (placeholder)

### Backward-compat / Breaking

- (placeholder)

### Ops Notes

- (placeholder)
  - Migration: (steps if any)
  - Rollback: (how to revert)

## [0.1.0] - 2025-10-19

### Added

- **App scaffold**: minimal backend, health check, unit tests.
- **CI (App)**: GitHub Actions builds, tests, logs in to ECR via OIDC, pushes image.
- **Versioning**: `VERSION` file drives image tagging (`<version>-<branch>-<sha>`).
- **Docs**: Architecture overview; ADRs for ASG vs ECS/EKS and NAT-per-AZ.

### Infra

- **Phase 2–3** (Env wiring): `dev`, `staging`, `prod` envs with remote state, providers, variables, orchestrators.
- **Phase 4** (Networking):
  - VPC with 2× public, 2× private-app, 2× private-db subnets across AZs.
  - NAT per AZ, IGW, route tables; SGs for `alb`, `app`, `db` (least privilege).
- **Phase 5** (IAM & ECR):
  - EC2 role + instance profile (SSM, ECR pull).
  - GitHub OIDC provider; CI roles for Terraform & ECR push.
  - ECR repo with lifecycle policy + scan-on-push.
- **Phase 6** (ALB → ASG):
  - Public ALB (HTTP; HTTPS conditional on ACM).
  - Target Group :8080; health checks on `/health`.
  - ASG in private subnets using Launch Template; user-data boots Docker, pulls image, runs on 8080.
- **Phase 7** (RDS):
  - Private DB subnet group, DB SG restricted to app SG.
  - Secrets Manager for credentials; random strong password.
  - RDS (encrypted; Multi-AZ toggle; backups; optional deletion protection).
- **Phase 8** (Endpoints & Observability):
  - VPC Endpoints: SSM, SSMMessages, Secrets Manager (interface), S3 (gateway).
  - CloudWatch alarms: ALB 5xx%, TG UnHealthyHostCount, ASG InService; optional RDS event subscription via SNS.

### Changed

- ALB configured to **HTTP-only** by default (no ACM) for simpler dev testing.
  - HTTPS becomes active by setting `acm_arn` in env `terraform.tfvars`.

### Fixed

- Typos and file naming (e.g., `observability/mai.tf` → `main.tf`).

### Backward-compat / Breaking

- None. First tagged release of infra/app.

### Ops Notes

- **Deploy flow**:
  1) Merge to `main` updates image tag and pushes to ECR.
  2) Terraform workflow applies to **dev** automatically (OIDC role).
- **App config**:
  - Image tag consumed from `deploy/image_tag` (updated by CI).
  - App listens on `:8080`; ALB health probe: `/health`.
- **DB access**:
  - App instances read DB creds from Secrets Manager (output: `secret_arn`).
  - RDS reachable only from App SG; not publicly accessible.
- **Costs**:
  - NAT per AZ, ALB, and RDS Multi-AZ (if enabled) incur ongoing charges.
  - Dev keeps costs lower (smaller instances, Multi-AZ off).

### Rollback

- **Infra**: `git revert` the infra change → push → Terraform apply (dev).
- **App**: set `deploy/image_tag` back to a known-good tag → apply; or scale ASG to 0 and re-deploy.

### Known Issues

- HTTPS not enabled by default (needs valid ACM cert ARN).
- ASG health relies on app exposing `/health` with 200 status.

## How to Cut a Release

1. Update `VERSION` (SemVer).
2. Update this file under **[Unreleased]** → move entries to a new `## [X.Y.Z] - YYYY-MM-DD`.
3. Commit: `chore(release): X.Y.Z` with summary of changes.
4. Tag (optional): `git tag -a vX.Y.Z -m "X.Y.Z"` and `git push --tags`.

## Linking PRs

Reference PRs/issues inline, e.g.:

- Fix ALB health probe timeout (#123)
- Add VPC endpoints (PR #45)
