# Terraform AWS ALB + Docker Nginx

This project provisions a simple AWS infrastructure using **Terraform**.

It deploys an **Application Load Balancer (ALB)** that routes traffic to **EC2 instances running Docker with an Nginx container**.

The infrastructure demonstrates a common DevOps architecture using **Infrastructure as Code (IaC)**.

---

## Architecture

Internet → Application Load Balancer → Target Group → EC2 → Docker → Nginx

The ALB distributes incoming HTTP traffic to EC2 instances running an Nginx container.

---

## Technologies Used

* Terraform
* AWS EC2
* AWS Application Load Balancer (ALB)
* AWS Target Groups
* AWS Security Groups
* AWS Auto Scaling
* Docker
* Nginx
* Bash (User Data script)

---

## Prerequisites

Before deploying this infrastructure, ensure you have:

* AWS account with configured credentials
* Terraform installed (v1.3 or newer)
* AWS CLI configured (`aws configure`)
* SSH key pair for EC2 access

---

## Resources Created

This Terraform project provisions the following AWS resources:

* **Application Load Balancer (ALB)** - Internet-facing load balancer
* **Target Group** - Routes traffic with health checks on port 80
* **Auto Scaling Group (ASG)** - Manages EC2 instance lifecycle (min: 1, max: 2)
* **Launch Template** - Blueprint for EC2 instance configuration
* **Security Groups** - Two separate groups for layered security:
  * ALB Security Group (allows HTTP from internet)
  * EC2 Security Group (allows HTTP from ALB only, SSH from authorized IP)
* **IAM Role & Instance Profile** - Permissions for EC2 instances
* **EC2 Instances** - Running Amazon Linux 2 with Docker and Nginx
* **ALB Listener** - Listens on port 80 and forwards to target group



## Security Best Practices

This project implements AWS security best practices:

### **Layered Security Groups**
- **ALB Security Group**: Accepts HTTP (port 80) from the internet (0.0.0.0/0)
- **EC2 Security Group**: 
  - Accepts HTTP (port 80) ONLY from the ALB security group
  - Accepts SSH (port 22) ONLY from authorized IP address
  - EC2 instances are NOT directly accessible from the internet

### **Principle of Least Privilege**
- All web traffic must flow through the Application Load Balancer
- EC2 instances hidden behind the ALB (cannot be accessed directly)
- SSH access restricted to a single IP address for administrative purposes

### **Defense in Depth**
- Multiple security layers (network-level security groups + application-level ALB)
- ALB provides DDoS protection and traffic filtering before reaching EC2
- Auto Scaling Group automatically replaces unhealthy instances

## Deployment

Initialize Terraform:

```bash
terraform init
```

Review the infrastructure plan:

```bash
terraform plan
```

Deploy the infrastructure:

```bash
terraform apply
```

Terraform will create all AWS resources and automatically configure the EC2 instances using the **user_data script**.

---

## User Data Script

The EC2 instance automatically installs Docker and runs an Nginx container:

```bash
#!/bin/bash
yum update -y
amazon-linux-extras install docker -y
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user
docker pull nginx
docker run -d --name nginx-container --restart always -p 80:80 nginx
```

This ensures that every EC2 instance automatically runs a web server container when launched.

---

## Accessing the Application

After deployment completes (wait **3–5 minutes** for the ALB health checks):

### Get the Load Balancer DNS name

```bash
terraform output alb_dns_name
```

Example output:

```
docker-lab-alb-1259050614.us-east-1.elb.amazonaws.com
```

### Open the application

```
http://<alb_dns_name>
```

You should see the **Nginx welcome page**.

---

## ⚠️ Cost Warning

This infrastructure creates real AWS resources and may incur charges
(typically **~$1–2 per day** depending on usage).

Remember to destroy the infrastructure when finished:

```bash
terraform destroy
```

---

## Project Structure

```
03-aws-alb-asg-terraform
│
├── backend.tf              # Terraform backend configuration
├── provider.tf             # AWS provider configuration
├── versions.tf             # Terraform and provider version constraints
├── main.tf                 # Main infrastructure resources
├── variables.tf            # Input variables
├── outputs.tf              # Terraform outputs (ALB DNS name)
├── user_data.sh            # EC2 bootstrap script (Docker + Nginx)
│
├── modules/
│   ├── ec2/
│   │   └── main.tf         # EC2 instance module
│   └── security-group/
│       └── main.tf         # Security group module
│
├── .gitignore
├── .terraform.lock.hcl
└── README.md
```
## Key Learnings

This project demonstrates:
- Infrastructure as Code with Terraform
- AWS load balancing and auto-scaling
- Containerized application deployment
- Security group configuration
- Automated infrastructure provisioning

## Project Goal

The goal of this project is to demonstrate how to deploy
a scalable web application infrastructure on AWS using Terraform.

The architecture uses an Application Load Balancer
and an Auto Scaling Group to provide high availability
and automatic scaling.

## Troubleshooting

**If instances show as unhealthy:**
- Wait 3-5 minutes for Docker installation to complete
- Check security groups allow port 80
- Verify user_data script executed successfully

**If ALB URL doesn't load:**
- Ensure instances are healthy in target group
- Check that subnets have internet gateway attached
- Verify security groups allow inbound HTTP traffic
---

## Author

Ivan Majic
DevOps Engineer
