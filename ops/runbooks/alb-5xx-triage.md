# Runbook — ALB 5xx Triage

**Purpose:**
Guide on diagnosing and resolving `5xx` errors detected by ALB CloudWatch alarms.

**Trigger:**

- `ALB_5xxRate` CloudWatch alarm firing
- Slack/SNS notification for elevated `HTTPCode_ELB_5XX_Count`
- Observed spike in latency or error rate on `/health`

## 1. Confirm the Alarm Context

### Gather from CloudWatch:

- Alarm name: `ALB_5xxRate`
- Region & environment: `dev` / `staging` / `prod`
- Timestamp of first trigger
- ALB DNS name & Target Group ARN
- RequestCount vs. 5XX ratio

### Verify in AWS Console:

1. Go to **EC2 → Target Groups → [your TG]**
2. Check **Targets → Health Status**
   - Look for `unhealthy` or `draining` targets
3. Confirm **last registered instance IDs** match latest ASG launch.

## 2. Identify Recent Changes

- Check latest deploy (ECR image tag + CI run)
- Look at `deploy/image_tag` vs. prior tag in ASG `user_data`
- Review commit history for:
  - App code changes (`main.py`, dependencies)
  - Infrastructure changes (ALB listener rules, security groups)

If a deploy happened in the last 10–15 minutes, suspect **app startup failure** or **health check misconfig**.

## 3. Inspect Logs

### On Instance:

```bash
# Connect to instance
aws ssm start-session --target <instance-id>

# Check app logs
sudo journalctl -u docker -n 50
sudo docker ps
sudo docker logs $(sudo docker ps -q --filter ancestor=<image>)
```
