variable "instance_type" {
  type = string
}

variable "alb_security_group_id" {
  description = "Security group ID for ALB"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for EC2 instances"
  type        = string
}

variable "key_name" {
  type = string
}

variable "user_data" {
  type = string
}

variable "instance_name" {
  type = string
}

variable "instance_profile_name" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}






