# **High Availability Web App on AWS**

This project provisions a **3-tier AWS architecture** designed for **high availability, scalability, and security**. The diagram (**aws-ha-webapp.mmd**) shows how all the components are wired together.

## **📐 Architecture Overview**

* **VPC (10.0.0.0/16)**
  Logical network boundary containing all resources.
* **Subnets**
  * **Public Subnets** (one per AZ): host the **Application Load Balancer (ALB)** and **NAT Gateways****.**
  * **Private App Subnets** (one per AZ): host **EC2 instances** in an **Auto Scaling Group****.**
  * **Private DB Subnets** (one per AZ): host the **RDS database** (primary + standby).
* **Gateways**
  * **Internet Gateway (IGW):** allows inbound/outbound access for the ALB.
  * **NAT Gateways:** allow EC2 instances in private subnets to reach the internet for updates without being exposed.
* **Application Layer**
  * **Application Load Balancer (ALB):** terminates HTTPS traffic and distributes requests evenly to healthy EC2 instances.
  * **EC2 Auto Scaling Group:** scales web/app servers up/down based on demand.
* **Database Layer**
  * **Amazon RDS (Multi-AZ):** primary database in one AZ with a standby/replica in the other for failover.

## **🔐 Security Design**

* **Security Groups** enforce least privilege:
  * Internet → ALB on port **443** only.
  * ALB → EC2 on port **8080** only.
  * EC2 → RDS on port **3306 (MySQL)** or **5432 (Postgres)** only.
* **No public IPs** on EC2 or RDS — access via **SSM Session Manager****.**
* **NACLs** can add another layer of subnet-level control.

## **⚡ How It Works**

1. **A user browses to **https://app.example.com**.**
2. DNS (Route 53) points to the **ALB** in public subnets.
3. The ALB forwards the request to a healthy **EC2 instance** in private subnets.
4. The EC2 instance queries the **RDS database** for data.
5. If traffic spikes, **Auto Scaling** adds EC2 instances automatically.
6. If an AZ fails, the app and database continue running in the second AZ.

## **✅ Benefits**

* **High Availability:** Resources are spread across **two Availability Zones****.**
* **Scalability:** Auto Scaling Group adjusts capacity based on demand.
* **Security:** Tiered isolation with least-privilege rules.
* **Resilience:** RDS Multi-AZ failover minimizes downtime.

## **📊 Diagram**

The full wiring is described in [aws-ha-webapp.mmd](./aws-ha-webapp.mmd). Render it with a Mermaid viewer (VS Code extension or GitHub preview).

Do you want me to also add a **“Getting Started” section** (with Terraform apply instructions + cost notes), so this README doubles as a hands-on guide for you?
