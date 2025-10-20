#!/usr/bin/env bash
set -euo pipefail

# -------------------------------------------------------------
# teardown_env.sh — Clean terraform destroy wrapper for sandboxes
# -------------------------------------------------------------
# Purpose:
#   Safely destroy a given environment's infrastructure.
#   Designed for dev/staging sandboxes; extra guardrails for prod.
#
# Usage:
#   ./ops/scripts/teardown_env.sh dev
#   ./ops/scripts/teardown_env.sh staging --yes
#   ENV=dev ./ops/scripts/teardown_env.sh
#   ./ops/scripts/teardown_env.sh prod  # will require explicit confirmation
#
# Flags:
#   -y | --yes           Auto-approve terraform destroy (no interactive prompt)
#   --no-color           Pass --no-color to terraform
#   --                    Everything after -- is passed to terraform destroy
#
# Notes:
# - This only destroys the selected env under infra/envs/<env>.
# - It does NOT touch the bootstrap remote state (S3 bucket/DynamoDB lock).
# - Destroying RDS will delete DATA; ensure snapshots/exports before running.
# -------------------------------------------------------------

ENV_NAME=${1:-${ENV:-}}
shift || true

if [[ -z "${ENV_NAME}" ]]; then
  echo "Usage: $0 <dev|staging|prod> [--yes] [--no-color] [-- <extra tf args>]" >&2
  exit 2
fi

# Defaults
AUTO_APPROVE=false
TF_NO_COLOR=false
EXTRA_ARGS=()

# Parse flags (until --)
while [[ $# -gt 0 ]]; do
  case "$1" in
    -y|--yes)
      AUTO_APPROVE=true; shift ;;
    --no-color)
      TF_NO_COLOR=true; shift ;;
    --)
      shift; EXTRA_ARGS=("$@"); break ;;
    *)
      EXTRA_ARGS+=("$1"); shift ;;
  esac
done

ENV_DIR="infra/envs/${ENV_NAME}"
if [[ ! -d "$ENV_DIR" ]]; then
  echo "[ERROR] Environment dir not found: $ENV_DIR" >&2
  exit 3
fi

# Guardrails for prod
if [[ "$ENV_NAME" == "prod" ]]; then
  echo "[GUARD] You are attempting to destroy **PROD**."
  echo "Type: destroy-prod  to proceed, or anything else to cancel."
  read -r CONFIRM
  if [[ "$CONFIRM" != "destroy-prod" ]]; then
    echo "[ABORT] Confirmation phrase not matched. Aborting." >&2
    exit 4
  fi
fi

# Summary prompt
if [[ "$AUTO_APPROVE" == false ]]; then
  echo "[WARN] This will run 'terraform destroy' in $ENV_DIR"
  echo "      Resources may include: VPC, Subnets, NATs, ALB, ASG/EC2, RDS (DATA LOSS), Endpoints."
  read -r -p "Proceed? (y/N): " ANS
  if [[ "${ANS:-}" != "y" && "${ANS:-}" != "Y" ]]; then
    echo "[ABORT] User declined."
    exit 0
  fi
fi

# Pre-flight checks
command -v terraform >/dev/null 2>&1 || { echo "[ERROR] terraform not found in PATH" >&2; exit 5; }

pushd "$ENV_DIR" >/dev/null

# Init backend
echo "[INFO] terraform init -backend-config=backend.hcl"
terraform init -backend-config=backend.hcl ${TF_NO_COLOR:+--no-color}

# Destroy
DESTROY_ARGS=(destroy)
$AUTO_APPROVE && DESTROY_ARGS+=( -auto-approve )
$TF_NO_COLOR && DESTROY_ARGS+=( --no-color )

# Append any extra args passed after --
DESTROY_ARGS+=("${EXTRA_ARGS[@]}")

echo "[INFO] terraform ${DESTROY_ARGS[*]}"
terraform "${DESTROY_ARGS[@]}"

popd >/dev/null

echo "[OK] Destroy completed for env: ${ENV_NAME}"
