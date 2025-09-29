# Architecture Overview — AWS High Availability Web App

## 🌐 Network Foundation

- **VPC (10.0.0.0/16):** Logical boundary for all resources.
- **Availability Zones:** Two AZs (e.g., `us-east-1a` and `us-east-1b`) for redundancy.
- **Subnets:**
  - **Public Subnets:** Host ALB + NAT Gateways.
  - **Private App Subnets:** Host EC2 instances (ASG).
  - **Private DB Subnets:** Host Amazon RDS instances.
- **Routing:**
  - Public subnets → Internet Gateway (inbound/outbound).
  - Private subnets → NAT Gateway for outbound (patching, ECR pulls).
  - No direct internet ingress into private subnets.

## ⚖️ Application Layer

- **Application Load Balancer (ALB):**
  - Internet-facing in public subnets.
  - Terminates HTTPS (ACM cert).
  - Health checks on `/health` endpoint.
  - Routes traffic to private ASG instances on port 8080.
- **Auto Scaling Group (ASG):**
  - EC2 instances across 2 AZs.
  - Launch Template installs Docker, pulls app image from ECR, runs container.
  - Desired/min/max capacity set per environment.
  - Scales out/in based on demand.

## 💾 Data Layer

- **Amazon RDS (Postgres/MySQL):**
  - Deployed in private DB subnets.
  - Multi-AZ enabled (primary + standby in different AZs).
  - Encrypted storage + backups (retention configurable).
  - Credentials stored in AWS Secrets Manager.
  - Only accessible from ASG security group.

## 🔐 Security Posture

- **Security Groups:**
  - ALB SG: Inbound 443 from internet → forward to ASG SG.
  - App SG: Inbound 8080 only from ALB SG → outbound 5432/3306 to DB SG.
  - DB SG: Inbound 5432/3306 only from App SG.
- **NACLs:** Optional subnet-level hardening; SGs are primary enforcement.
- **IAM:**
  - EC2 instances get SSM + ECR pull permissions.
  - GitHub Actions assume role via OIDC for CI/CD.
- **Access:** No SSH. All access via Session Manager (SSM).

## 📈 High Availability Story

- **Multi-AZ Everywhere:**
  - ALB deployed in both public subnets (across 2 AZs).
  - ASG spreads EC2 instances across AZs.
  - RDS has standby in second AZ.
- **Failure scenarios:**
  - If one AZ fails → ALB routes to remaining AZ; ASG keeps capacity; RDS fails over.
  - If one EC2 fails → ASG replaces it automatically.
  - If DB instance fails → automatic failover to standby.

## 🔄 Traffic Flow

1. User → Internet → **ALB (443)**.
2. ALB forwards to **EC2 instances (8080)** in private app subnets.
3. EC2 instances process requests, query **RDS (5432/3306)** in private DB subnets.
4. Responses flow back through ALB to user.

## ✅ Validation Points

- ALB DNS returns app response across AZs.
- Terminating one instance → ASG replaces it.
- Triggering RDS failover → app reconnects seamlessly.
- Security groups block any direct DB or EC2 access from the internet.
