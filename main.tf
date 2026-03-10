module "security_group" {
  source   = "./modules/security-group"
  
}
module "ec2" {
  source = "./modules/ec2"


  instance_type         = var.instance_type
  security_group_id     = module.security_group.ec2_security_group_id
  alb_security_group_id = module.security_group.alb_security_group_id
  key_name              = var.key_name
  user_data             = base64encode(file("user_data.sh"))
  subnet_ids            = data.aws_subnets.default.ids
  vpc_id                = data.aws_vpc.default.id
  instance_name         = "dev"
  instance_profile_name = module.iam_ec2.instance_profile_name  
}
module "iam_ec2" {
  source = "./modules/iam-ec2"
}

data "aws_subnets" "default" {
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}
data "aws_vpc" "default" {
  default = true
}