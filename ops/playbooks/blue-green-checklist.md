# Playbook — Blue/Green Rollout (ALB + second Target Group)

**Purpose:**
Safely deploy a new app version by standing up a parallel environment (**Green**) alongside the current **Blue**, then switching traffic at the ALB. Fast rollback = flip back.

---

## 0) Prereqs & Concepts

- **Blue** = current Target Group (TG) serving traffic (e.g., `aws-ha-webapp-tg`).
- **Green** = new TG + ASG (or same ASG pointing to a second TG) with the new image tag.
- **Cutover** is done at the **ALB listener** (swap TG or use weighted forwarding).
- Health check path: `/health` returns 200 quickly.

> Infra options:
>
> - **Simple swap:** one listener, switch its default action TG.
> - **Weighted shift:** listener rule forwards X% to Green, then ramp (requires rule with `forward` + weights).

---

## 1) Prechecks

- **Infra in place**
  - Second TG exists (e.g., `aws-ha-webapp-tg-green`) in same VPC.
  - ASG is registering instances to **Green** TG.
  - Security Groups: ALB → App(8080) OK.
- **Green health**
  - `aws elbv2 describe-target-health --target-group-arn <GREEN_TG_ARN>` → all `healthy`.
  - `/health` is fast (≤100ms), returns `200`.
- **Image/version**
  - `deploy/image_tag` matches intended version (or pinned in ASG user_data).
- **Observability ready**
  - Alarms: TG `UnHealthyHostCount`, ALB 5xx% enabled.
  - Dashboards/metrics visible.

---

## 2) Warm & Verify Green (no user traffic yet)

- **Direct test via target IP (SSM port-forward or curl on instance):**
  - `docker ps` shows app running.
  - `curl -s localhost:8080/health` → `200`, check logs.
- **Synthetic test through ALB (rule-based URL if available):**
  - Temporarily add path rule `/canary/*` → GREEN TG.
  - Hit `http(s)://ALB-DNS/canary/health` → `200`.

---

## 3) Cutover Options

### A) Instant Swap (default action TG flip)

- Change ALB **listener default action** from **BLUE_TG** → **GREEN_TG**.
- Keep Blue registered for fast rollback.

### B) Weighted Shift (gradual)

- Add/modify listener rule:
  ```hcl
  default_action {
    type = "forward"
    forward {
      target_group {
        arn    = BLUE_TG_ARN
        weight = 80
      }
      target_group {
        arn    = GREEN_TG_ARN
        weight = 20
      }
    }
  }
  ```
