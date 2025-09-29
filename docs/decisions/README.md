# Architecture Decision Records (ADRs)

This folder documents key **architecture decisions** for the AWS High Availability Web App project.
Each ADR captures the **context, decision, consequences, and alternatives** so we can revisit or evolve choices later.

## 📂 ADR Index

- **[0001-use-asg-over-ecs.md](./0001-use-asg-over-ecs.md)**
  Use **EC2 Auto Scaling Group (ASG)** with Dockerized app instead of ECS/EKS.
  *Why:* Simpler to explain, shows raw AWS primitives, easier for portfolio learning.
- **[0002-nat-per-az-for-ha.md](./0002-nat-per-az-for-ha.md)**
  Deploy **one NAT Gateway per AZ** instead of a single shared NAT.
  *Why:* Ensures high availability at the cost of ~$30/month extra per NAT.
- **[0003-iam-oidc-ci.md](./0003-iam-oidc-ci.md)**
  Use **GitHub OIDC roles** instead of long-lived IAM keys for CI/CD.
  *Why:* Eliminates static secrets, supports least privilege, and improves security posture.

## 🧭 How to Use This Folder

- Each new significant decision should have its own ADR (increment the number).
- Use the template: **Context → Decision → Consequences → Alternatives → Status**.
- Never delete old ADRs; mark them as **Superseded** if replaced by new decisions.
- This creates a transparent log of architectural evolution for both learning and auditing.
