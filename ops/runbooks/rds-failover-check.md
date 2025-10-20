# Runbook — RDS Failover Check

**Purpose:**
Test and verify that the RDS database can fail over cleanly between Availability Zones,
and that the application layer reconnects automatically without data loss.

**When to Run:**

- Quarterly HA validation or DR drills
- After enabling Multi-AZ or restoring from snapshot
- Before promoting staging to production

---

## 1. Preparation

### Confirm Environment

- Target environment: `dev` / `staging` / `prod`
- RDS identifier: `aws-ha-webapp-db`
- Engine: PostgreSQL (or MySQL)
- Multi-AZ: **Enabled**
- DB endpoint type: Writer endpoint (not read-replica)

### Prerequisites

- AWS CLI configured with RDS permissions
- Application running behind ALB → ASG (connected via `DATABASE_URL`)
- `ping_db()` or `/health` endpoint available for checking app DB connectivity

---

## 2. Simulate Failover

> ⚠️ Expect **30–60 seconds** of DB unavailability during the event.
> Failover switches to the standby in the other AZ; DNS endpoint remains the same.

### Via AWS CLI

```bash
aws rds reboot-db-instance \
  --db-instance-identifier aws-ha-webapp-db \
  --force-failover
```
