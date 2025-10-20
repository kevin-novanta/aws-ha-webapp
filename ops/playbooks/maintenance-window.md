# Playbook — Planned Maintenance Window

**Purpose**
Coordinate infra/app changes with **minimal user impact**. Covers comms, traffic draining, verification, and rollback.

## 0) Scope & Approvals

- **Change type:** (e.g., RDS patch, ALB/ASG rollout, VPC change)
- **Environments:** dev / staging / prod
- **Window:** YYYY-MM-DD HH:MM–HH:MM (TZ)
- **Approvals:** Change Manager ✅ | App Owner ✅ | DB Owner ✅ | SRE On-call ✅

## 1) Notify Stakeholders

### T–24h (and T–1h) Announcements

- **Channels:** #eng-ops, status page, email distros
- **Template**
  > *Planned maintenance* on **<env>** from **<start>–<end>**.
  > Impact: brief health check blips; no data loss expected.
  > Tracking ticket: <link>. Contact: @oncall.
  >

### Page On-call

- Confirm escalation policy active and coverage during window.

## 2) Pre-Checks (T–15m)

- **Traffic level**: Confirm off-peak.
- **Alarms clear**: ALB 5xx, TG UnHealthyHostCount, ASG InService.
- **Backups**: Latest RDS automated snapshots exist.
- **Version/tag**: `deploy/image_tag` matches intended version (if app change).
- **Rollback artifact**: Identify last known-good tag.

Commands (examples):

```bash
# ALB target health
aws elbv2 describe-target-health --target-group-arn <TG_ARN>

# ASG capacity
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names aws-ha-webapp-asg \
  --query 'AutoScalingGroups[0].[MinSize,DesiredCapacity,MaxSize]' --output table

# RDS latest snapshots (if any)
aws rds describe-db-snapshots --db-instance-identifier aws-ha-webapp-db --snapshot-type automated
```
