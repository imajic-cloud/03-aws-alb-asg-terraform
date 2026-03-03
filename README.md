# Terraform AWS ALB + ASG Infrastructure

## Overview

Production-style AWS infrastructure built with Terraform.

This project deploys a Dockerized Nginx application behind:

- Application Load Balancer (ALB)
- Auto Scaling Group (ASG)
- Launch Template

Infrastructure is fully reproducible and designed to be created and destroyed safely.

---

## Architecture

```
Internet
   │
   ▼
Application Load Balancer (ALB)
   │
   ▼
Target Group (HTTP health checks)
   │
   ▼
Auto Scaling Group (min=1, max=2)
   │
   ▼
EC2 Instance (Docker + Nginx)
```

---

## Key Features

- Remote backend (S3 + DynamoDB state locking)
- Launch Template (immutable infrastructure)
- Auto Scaling Group (self-healing)
- ALB with health checks
- Proper security group separation (ALB → EC2)
- IAM instance profile
- Docker deployment via user_data
- Infrastructure lifecycle management

---

## Terraform Commands

```bash
terraform init
terraform plan
terraform apply
terraform destroy
```

---

## What This Demonstrates

- Immutable infrastructure principles
- High availability design
- Self-healing systems
- Terraform module structure
- AWS networking fundamentals