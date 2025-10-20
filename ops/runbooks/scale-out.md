# Runbook — Manual Scale-Out

**Purpose:**
Guide for manually increasing or decreasing Auto Scaling Group (ASG) capacity and validating that new instances join the ALB target group in a healthy state.

**When to Run:**

- App latency or CPU alarms trigger
- Manual load test or demo scenario (e.g., simulating Black Friday)
- Infrastructure validation after AMI/image update
- ASG scaling policies disabled or misconfigured

## 1. Pre-Checks

### Confirm Current State

```bash
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names aws-ha-webapp-asg \
  --query 'AutoScalingGroups[0].[MinSize,DesiredCapacity,MaxSize,Instances[].InstanceId]' \
  --output table
```
