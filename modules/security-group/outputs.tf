output "alb_security_group_id" {
  description = "Security group ID for ALB"
  value       = aws_security_group.alb_sg.id
}

output "ec2_security_group_id" {
  description = "Security group ID for EC2"
  value       = aws_security_group.ec2_sg.id
}

output "security_group_id" {
  description = "Security group ID (legacy - EC2)"
  value       = aws_security_group.ec2_sg.id
}