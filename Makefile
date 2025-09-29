

# Makefile — aws-ha-webapp
# Fast commands for bootstrap/plan/apply/build/smoke/destroy.
# Usage examples:
#   make help
#   make bootstrap
#   make plan ENV=dev
#   make apply ENV=staging
#   make destroy ENV=dev
#   make build-app ENV=dev
#   make smoke ENV=dev

SHELL := /bin/bash

# -------- Config knobs --------
ENV ?= dev                       # dev | staging | prod
TF_ENV_DIR := infra/envs/$(ENV)
BOOTSTRAP_DIR := infra/bootstrap

TF := terraform -chdir=$(TF_ENV_DIR)
BOOT_TF := terraform -chdir=$(BOOTSTRAP_DIR)
BACKEND := -backend-config=backend.hcl

# Pass-throughs (optional)
# export AWS_PROFILE ?= default
# export AWS_REGION  ?= us-east-1

.PHONY: help bootstrap fmt validate plan apply destroy outputs build-app smoke

help:
	@echo "Targets:"
	@echo "  bootstrap   - create remote state (S3) + lock table (DynamoDB)"
	@echo "  fmt         - terraform fmt across repo"
	@echo "  validate    - terraform validate for current ENV"
	@echo "  plan        - terraform init (+backend) & plan for ENV=$(ENV)"
	@echo "  apply       - terraform init (+backend) & apply for ENV=$(ENV)"
	@echo "  destroy     - terraform destroy for ENV=$(ENV)"
	@echo "  outputs     - show terraform outputs for ENV=$(ENV)"
	@echo "  build-app   - build & push app image to ECR (updates deploy/image_tag)"
	@echo "  smoke       - curl ALB /health using terraform output alb_dns"
	@echo "\nExamples: make apply ENV=dev | make build-app ENV=staging | make smoke ENV=prod"

# -------- Bootstrap remote state (run once per AWS account) --------
bootstrap:
	@echo "[bootstrap] Initializing remote state backend..."
	$(BOOT_TF) init
	@echo "[bootstrap] Applying S3 bucket + DynamoDB lock table..."
	$(BOOT_TF) apply -auto-approve
	@echo "[bootstrap] Done. Use the outputs in envs/*/backend.hcl."

# -------- Lint & validate --------
fmt:
	@echo "[fmt] Running terraform fmt -recursive ..."
	terraform fmt -recursive

validate:
	@echo "[validate] ENV=$(ENV)"
	@test -f $(TF_ENV_DIR)/backend.hcl || (echo "Missing $(TF_ENV_DIR)/backend.hcl" && exit 1)
	$(TF) init $(BACKEND) -upgrade
	$(TF) validate

# -------- Plan/Apply/Destroy for selected ENV --------
plan: fmt
	@echo "[plan] ENV=$(ENV)"
	@test -f $(TF_ENV_DIR)/backend.hcl || (echo "Missing $(TF_ENV_DIR)/backend.hcl" && exit 1)
	$(TF) init $(BACKEND)
	$(TF) plan

apply: fmt
	@echo "[apply] ENV=$(ENV)"
	@test -f $(TF_ENV_DIR)/backend.hcl || (echo "Missing $(TF_ENV_DIR)/backend.hcl" && exit 1)
	$(TF) init $(BACKEND)
	$(TF) apply -auto-approve

destroy:
	@echo "[destroy] ENV=$(ENV)"
	$(TF) destroy -auto-approve || true

outputs:
	@echo "[outputs] ENV=$(ENV)"
	$(TF) output

# -------- App image pipeline (build & push to ECR) --------
build-app:
	@echo "[build-app] ENV=$(ENV) — building & publishing Docker image to ECR..."
	bash deploy/ecr_publish.sh $(ENV)
	@echo "[build-app] Done. Current tag: $$(cat deploy/image_tag 2>/dev/null || echo '(none)')"

# -------- Smoke test via ALB /health --------
# Uses terraform output `alb_dns` if present. You can override with ALB_URL.
smoke:
	@echo "[smoke] ENV=$(ENV)"
	@ALB=$$($(TF) output -raw alb_dns 2>/dev/null || true); \
	 if [ -n "$$ALB" ]; then \
	   echo "[smoke] Using ALB from terraform output: $$ALB"; \
	 else \
	   ALB="$${ALB_URL}"; \
	   if [ -z "$$ALB" ]; then echo "alb_dns output not found. Pass ALB_URL=your-alb-dns" && exit 1; fi; \
	 fi; \
	 bash ops/scripts/smoke_test.sh "$$ALB"