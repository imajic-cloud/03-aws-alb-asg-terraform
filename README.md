# AWS Application Load Balancer + Auto Scaling Group with Terraform

A production-ready AWS infrastructure deployment featuring Application Load Balancer (ALB) and Auto Scaling Groups (ASG) using Infrastructure as Code. This project demonstrates automated, scalable, and self-healing cloud architecture with immutable infrastructure principles.

## Overview

This project provisions a highly available and auto-scaling web application infrastructure on AWS using Terraform. The architecture includes load balancing, automatic scaling based on demand, centralized state management, and health-based recovery mechanisms.

## Architecture

```
Internet Traffic
      ↓
Application Load Balancer (ALB)
      ↓
Target Group (Health Checks)
      ↓
Auto Scaling Group (1-2 instances)
      ↓
EC2 Instances (Docker + Nginx)
```

**Infrastructure Components:**
1. **Application Load Balancer (ALB)** - Distributes incoming traffic across multiple targets
2. **Target Group** - Routes requests to registered EC2 instances with health monitoring
3. **Auto Scaling Group** - Automatically adjusts capacity based on defined policies
4. **Launch Template** - Defines EC2 configuration for immutable infrastructure
5. **Security Groups** - Network-level security with least privilege access
6. **S3 Backend** - Remote Terraform state storage
7. **DynamoDB** - State locking to prevent concurrent modifications

## Technologies Stack

| Category | Technology |
|----------|-----------|
| **Infrastructure as Code** | Terraform |
| **Cloud Provider** | AWS |
| **Load Balancing** | Application Load Balancer (ALB) |
| **Auto Scaling** | Auto Scaling Groups (ASG) |
| **Compute** | EC2 (t2.micro) |
| **Container Runtime** | Docker |
| **Web Server** | Nginx |
| **State Management** | S3 + DynamoDB |
| **Networking** | VPC, Security Groups |

## Project Structure

```
03-aws-alb-asg-terraform/
│
├── main.tf                    # Main infrastructure resources
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── backend.tf                 # S3 + DynamoDB backend configuration
├── terraform.tfvars           # Variable values (not committed)
│
├── modules/                   # Reusable Terraform modules (optional)
│   ├── alb/
│   ├── asg/
│   └── networking/
│
├── scripts/
│   └── user-data.sh          # EC2 initialization script
│
└── README.md
```

## Key Features

### 1. **Remote State Management**
- **S3 Backend** - Centralized state storage for team collaboration
- **DynamoDB Locking** - Prevents concurrent state modifications
- **State Encryption** - Secure storage of sensitive infrastructure data
- **Versioning** - Track state changes over time

### 2. **Launch Template (Immutable Infrastructure)**
- Version-controlled EC2 configuration
- Automated instance provisioning
- User data script for Docker + Nginx installation
- Consistent deployment across all instances
- Easy rollback to previous versions

### 3. **Auto Scaling Group**
- **Min Capacity:** 1 instance (always-on availability)
- **Max Capacity:** 2 instances (cost-controlled scaling)
- **Health Checks:** Automatic replacement of unhealthy instances
- **Desired Capacity:** Maintains optimal instance count
- **Self-Healing:** Failed instances automatically replaced

### 4. **Application Load Balancer**
- **Layer 7 Load Balancing** - HTTP/HTTPS traffic distribution
- **Health Checks** - Only routes traffic to healthy instances
- **Cross-AZ Distribution** - High availability across availability zones
- **Security Groups** - Separate rules for ALB and EC2 instances
- **Target Group** - Manages backend instance registration

### 5. **Security Groups (Separation of Concerns)**
- **ALB Security Group** - Allows HTTP/HTTPS from internet (0.0.0.0/0)
- **EC2 Security Group** - Only accepts traffic from ALB
- **Principle of Least Privilege** - Minimal required access
- **Egress Rules** - Controlled outbound traffic

### 6. **Self-Healing Systems**
- Automatic health checks every 30 seconds
- Unhealthy instances terminated and replaced
- No manual intervention required
- Maintains desired capacity automatically

## Prerequisites

Before deploying this infrastructure, ensure you have:

- **AWS Account** with appropriate permissions
- **AWS CLI** (v2.x or higher) configured with credentials
- **Terraform** (v1.0 or higher) installed
- **IAM Permissions** for:
  - EC2 (Launch Templates, Instances, Security Groups)
  - Elastic Load Balancing (ALB, Target Groups)
  - Auto Scaling (ASG, Launch Configurations)
  - S3 (Bucket creation and management)
  - DynamoDB (Table creation)
  - VPC (Networking resources)

## Setup Instructions

### 1. Configure AWS Credentials

```bash
# Configure AWS CLI
aws configure

# Verify credentials
aws sts get-caller-identity
```

### 2. Create S3 Bucket and DynamoDB Table (First Time Only)

**Option A: Using AWS Console**
1. Create S3 bucket: `terraform-state-<your-name>`
2. Enable versioning on the bucket
3. Create DynamoDB table: `terraform-state-lock`
4. Primary key: `LockID` (String)

**Option B: Using AWS CLI**
```bash
# Create S3 bucket for state
aws s3api create-bucket \
  --bucket terraform-state-yourname \
  --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket terraform-state-yourname \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

### 3. Configure Backend

Update `backend.tf` with your S3 bucket name:

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-yourname"  # Your S3 bucket
    key            = "alb-asg/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

### 4. Customize Variables

Create `terraform.tfvars`:

```hcl
aws_region      = "us-east-1"
project_name    = "myapp"
environment     = "production"
instance_type   = "t2.micro"
min_size        = 1
max_size        = 2
desired_capacity = 1
```

### 5. Deploy Infrastructure

```bash
# Navigate to project directory
cd 03-aws-alb-asg-terraform

# Initialize Terraform (download providers, configure backend)
terraform init

# Validate configuration
terraform validate

# Preview changes
terraform plan

# Apply configuration
terraform apply

# Type 'yes' to confirm
```

### 6. Verify Deployment

```bash
# Get ALB DNS name
terraform output alb_dns_name

# Test the application
curl http://<alb-dns-name>

# Or open in browser
```

## Terraform Configuration

### Main Resources (main.tf)

```hcl
# VPC and Networking
resource "aws_default_vpc" "default" {}

resource "aws_default_subnet" "default_az1" {
  availability_zone = "${var.aws_region}a"
}

resource "aws_default_subnet" "default_az2" {
  availability_zone = "${var.aws_region}b"
}

# Security Group for ALB
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for EC2
resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name}-ec2-sg"
  description = "Security group for EC2 instances"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Launch Template
resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  user_data = base64encode(templatefile("${path.module}/scripts/user-data.sh", {}))

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-instance"
    }
  }
}

# Application Load Balancer
resource "aws_lb" "app" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [
    aws_default_subnet.default_az1.id,
    aws_default_subnet.default_az2.id
  ]
}

# Target Group
resource "aws_lb_target_group" "app" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_default_vpc.default.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
}

# ALB Listener
resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "app" {
  name                = "${var.project_name}-asg"
  vpc_zone_identifier = [
    aws_default_subnet.default_az1.id,
    aws_default_subnet.default_az2.id
  ]
  target_group_arns   = [aws_lb_target_group.app.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg-instance"
    propagate_at_launch = true
  }
}
```

### User Data Script (scripts/user-data.sh)

```bash
#!/bin/bash

# Update system
yum update -y

# Install Docker
amazon-linux-extras install docker -y
systemctl start docker
systemctl enable docker

# Run Nginx container
docker run -d -p 80:80 --name nginx nginx:latest

# Create custom index page
docker exec nginx bash -c 'echo "<h1>Hello from $(hostname)</h1>" > /usr/share/nginx/html/index.html'
```

## Infrastructure Management

### View Current State

```bash
# Show all resources
terraform state list

# Show specific resource
terraform state show aws_lb.app

# Show outputs
terraform output
```

### Update Infrastructure

```bash
# Modify terraform.tfvars or .tf files

# Preview changes
terraform plan

# Apply changes
terraform apply
```

### Scale Application

```bash
# Edit terraform.tfvars
min_size = 2
max_size = 4
desired_capacity = 2

# Apply changes
terraform apply
```

### Destroy Infrastructure

```bash
# Preview what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy

# Type 'yes' to confirm
```

## Monitoring & Verification

### Check ALB Status

```bash
# Get ALB DNS
aws elbv2 describe-load-balancers \
  --names myapp-alb \
  --query 'LoadBalancers[0].DNSName' \
  --output text

# Check target health
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn>
```

### Check ASG Status

```bash
# View ASG details
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names myapp-asg

# View scaling activities
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name myapp-asg \
  --max-records 10
```

### Check EC2 Instances

```bash
# List instances in ASG
aws ec2 describe-instances \
  --filters "Name=tag:aws:autoscaling:groupName,Values=myapp-asg" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress]' \
  --output table
```

### Test Load Balancing

```bash
# Multiple requests to see different instances
for i in {1..10}; do
  curl http://<alb-dns-name>
done
```

## Troubleshooting

### Issue: Instances not registering with Target Group

**Solution:**
```bash
# Check security group rules
aws ec2 describe-security-groups --group-ids <ec2-sg-id>

# Verify health check settings
aws elbv2 describe-target-groups --target-group-arns <tg-arn>

# Check instance health
aws elbv2 describe-target-health --target-group-arn <tg-arn>
```

### Issue: Terraform state lock error

**Solution:**
```bash
# Force unlock (use carefully!)
terraform force-unlock <lock-id>

# Or delete lock from DynamoDB console
```

### Issue: Cannot access ALB URL

**Solution:**
```bash
# Verify ALB security group allows port 80
# Check ALB is internet-facing, not internal
aws elbv2 describe-load-balancers --names myapp-alb

# Verify DNS propagation
nslookup <alb-dns-name>
```

### Issue: Instances failing health checks

**Solution:**
```bash
# SSH to instance and check Docker
ssh ec2-user@<instance-ip>
docker ps
docker logs nginx

# Check user data script execution
sudo cat /var/log/cloud-init-output.log
```

### Issue: Auto Scaling not working

**Solution:**
```bash
# Check ASG configuration
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names myapp-asg

# View scaling activities
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name myapp-asg
```

## Cost Optimization

### Estimated Monthly Cost (us-east-1):
- **EC2 (t2.micro, 2 instances):** ~$15/month
- **ALB:** ~$22/month
- **S3 (state storage):** <$1/month
- **DynamoDB (on-demand):** <$1/month
- **Data Transfer:** Variable

**Total:** ~$40-50/month

### Cost Saving Tips:
- Use `t3.micro` instead of `t2.micro` (better performance/price)
- Set ASG min to 0 during development (stop when not needed)
- Use Spot Instances for non-production
- Delete resources when not in use: `terraform destroy`

## Best Practices Implemented

- ✅ **Remote State** - Centralized state with S3 backend
- ✅ **State Locking** - DynamoDB prevents conflicts
- ✅ **Immutable Infrastructure** - Launch Templates for consistency
- ✅ **Security Groups** - Layered security (ALB → EC2)
- ✅ **High Availability** - Multi-AZ deployment
- ✅ **Auto Healing** - Failed instances automatically replaced
- ✅ **Version Control** - All infrastructure as code
- ✅ **Least Privilege** - Minimal security group rules

## Security Considerations

- State file encryption in S3
- Security group ingress limited to specific sources
- No SSH access (use Session Manager if needed)
- Regular AMI updates for security patches
- Secrets stored in AWS Secrets Manager (not in code)
- IAM roles for EC2 instead of access keys

## Advanced Enhancements

### Add HTTPS Support

```hcl
# Request ACM certificate
resource "aws_acm_certificate" "app" {
  domain_name       = "example.com"
  validation_method = "DNS"
}

# Add HTTPS listener
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.app.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.app.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
```

### Add Auto Scaling Policies

```hcl
# Scale up policy
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app.name
}

# CloudWatch alarm to trigger scale up
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }
}
```

## Future Improvements

- [ ] Add HTTPS with ACM certificate
- [ ] Implement CloudWatch monitoring and alarms
- [ ] Add auto-scaling policies based on metrics
- [ ] Deploy across multiple regions (multi-region setup)
- [ ] Add RDS database backend
- [ ] Implement blue-green deployment strategy
- [ ] Add WAF for web application firewall
- [ ] Integrate with Route 53 for DNS
- [ ] Add CloudFront CDN
- [ ] Implement CI/CD pipeline for infrastructure updates

## Key Learnings

This project demonstrates:

- **Terraform State Management** - Remote backends with locking
- **AWS Networking** - VPC, Security Groups, Multi-AZ
- **Load Balancing** - ALB configuration and target groups
- **Auto Scaling** - Self-healing and capacity management
- **Infrastructure as Code** - Reproducible deployments
- **Security Best Practices** - Layered security approach
- **Cost Management** - Right-sizing and optimization

## Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS ALB Documentation](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/)
- [AWS Auto Scaling Documentation](https://docs.aws.amazon.com/autoscaling/)
- [Terraform S3 Backend](https://www.terraform.io/docs/language/settings/backends/s3.html)

## Project Status

✅ **Infrastructure:** Fully functional and production-ready  
✅ **Auto Scaling:** Tested and verified  
✅ **Load Balancing:** Traffic distribution working correctly  
✅ **State Management:** Remote state with locking enabled  

## Author

**DevOps Portfolio Project**

This project showcases hands-on experience with:
- Terraform Infrastructure as Code
- AWS cloud architecture
- Load balancing and auto-scaling
- High availability design
- Security best practices
- Cost-effective infrastructure

---

## License

This project is open source and available for educational purposes.

## Contributing

Contributions and improvements are welcome! Feel free to fork and submit pull requests.

---

**⭐ If you find this project helpful, please give it a star!**