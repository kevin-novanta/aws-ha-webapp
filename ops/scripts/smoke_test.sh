

#!/usr/bin/env bash
set -euo pipefail

# -------------------------------------------------------------
# smoke_test.sh — Curl ALB /health with retries; fail if not 200
# -------------------------------------------------------------
# Usage:
#   ENV=dev ./ops/scripts/smoke_test.sh
#   ALB_DNS=my-alb-123.us-east-1.elb.amazonaws.com ./ops/scripts/smoke_test.sh
#   PROTO=https RETRIES=30 SLEEP=5 ./ops/scripts/smoke_test.sh
#
# Env vars:
#   ALB_DNS   : (optional) ALB DNS name. If not set, script will read from Terraform outputs.
#   ENV       : (optional) env folder to read outputs from (dev|staging|prod). Default: dev
#   PROTO     : http or https. Default: http
#   RETRIES   : number of attempts. Default: 20
#   SLEEP     : seconds between attempts. Default: 5
# -------------------------------------------------------------

ENV=${ENV:-dev}
PROTO=${PROTO:-http}
RETRIES=${RETRIES:-20}
SLEEP=${SLEEP:-5}

ALB_DNS=${ALB_DNS:-}

if [[ -z "$ALB_DNS" ]]; then
  ENV_DIR="infra/envs/${ENV}"
  if [[ ! -d "$ENV_DIR" ]]; then
    echo "[ERROR] Environment dir not found: $ENV_DIR" >&2
    exit 2
  fi
  echo "[INFO] Resolving ALB DNS from Terraform outputs in $ENV_DIR ..."
  # Try common output names
  set +e
  ALB_DNS=$(terraform -chdir="$ENV_DIR" output -raw alb_dns_name 2>/dev/null)
  if [[ -z "$ALB_DNS" ]]; then
    ALB_DNS=$(terraform -chdir="$ENV_DIR" output -raw alb_dns 2>/dev/null)
  fi
  set -e
  if [[ -z "$ALB_DNS" ]]; then
    echo "[ERROR] Could not resolve ALB DNS from Terraform outputs (tried alb_dns_name, alb_dns)." >&2
    echo "        Provide ALB_DNS explicitly or ensure outputs exist." >&2
    exit 3
  fi
fi

URL="${PROTO}://${ALB_DNS}/health"

echo "[INFO] Smoking: $URL"

for ((i=1; i<=RETRIES; i++)); do
  TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  # Follow redirects just in case (HTTP->HTTPS)
  STATUS=$(curl -sS -L -m 5 -o /dev/null -w "%{http_code}" "$URL" || true)
  if [[ "$STATUS" == "200" ]]; then
    echo "[OK] $TS attempt $i/${RETRIES}: /health returned 200"
    exit 0
  else
    echo "[WAIT] $TS attempt $i/${RETRIES}: got $STATUS, retrying in ${SLEEP}s..."
    sleep "$SLEEP"
  fi
done

echo "[FAIL] /health did not return 200 after ${RETRIES} attempts" >&2
exit 1