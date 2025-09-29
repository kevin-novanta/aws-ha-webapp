# Run Costs — AWS High Availability Web App

## 🎯 Purpose

Track expected monthly costs for key AWS components in this project.
This helps prevent surprise bills and documents which features we toggle **on/off** in each environment (dev, staging, prod).

## 📦 Core Components & Pricing (approximate, us-east-1)


| Component                      | Cost (Monthly)             | Notes                                        |
| ------------------------------ | -------------------------- | -------------------------------------------- |
| **NAT Gateway**                | ~$32 each + $0.045/GB data | One per AZ recommended for HA.               |
| **Application LB (ALB)**       | ~$16 base + LCUs           | Scales with requests and new connections.    |
| **EC2 t3.micro**               | ~$8.50 each                | Used for app tier in dev.                    |
| **RDS db.t3.micro (Multi-AZ)** | ~$30–$60 base + storage   | Standby doubles cost; prod uses Multi-AZ.    |
| **ECR**                        | $0.10/GB-month             | Free for first 500MB.                        |
| **CloudWatch Alarms**          | $0.10/alarm/month          | Nominal, add SNS cost if notifications used. |

## 🔧 Environment Toggles

### Dev

- **NAT Gateways:** 1 (cheaper, SPOF acceptable).
- **RDS Multi-AZ:** Off (single instance).
- **EC2 Instances:** Smallest sizes (`t3.micro`).
- **Alarms:** Minimal.
- **Expected Monthly:** ~$40–$70 depending on usage.

### Staging

- **NAT Gateways:** 2 (HA).
- **RDS Multi-AZ:** On.
- **EC2 Instances:** Medium size (`t3.small` or `t3.medium`).
- **Alarms:** Full set enabled.
- **Expected Monthly:** ~$120–$180.

### Prod

- **NAT Gateways:** 2 (HA).
- **RDS Multi-AZ:** On, deletion protection enabled.
- **EC2 Instances:** Larger instance class (scale with load).
- **ALB Access Logs:** On (adds S3 storage cost).
- **Alarms:** Full set with SNS notifications.
- **Expected Monthly:** $250+ depending on scale and data transfer.

## 📝 Notes

- **Cross-AZ data transfer:** $0.01/GB. Matters if using single NAT in dev.
- **S3/Secrets Manager/SSM endpoints:** Optional, add small hourly cost per AZ but reduce egress charges.
- **Spot Instances:** Could reduce EC2 cost but less predictable.
- **Shutdown Policy:** Destroy dev envs when not in use to save money.

## ✅ Summary

- Use **1 NAT + single-AZ RDS** in **dev** for savings.
- Always use **2 NATs + Multi-AZ RDS** in **prod** for reliability.
- Document these toggles so cost tradeoffs are explicit and intentional.
