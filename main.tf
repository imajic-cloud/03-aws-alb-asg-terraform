module "security_group" {
  source   = "./modules/security-group"
  name     = "web-sg"
  app_port = 3000
}
module "ec2" {
  source = "./modules/ec2"


  instance_type     = "t2.micro"
  security_group_id = module.security_group.security_group_id
  key_name          = "project3-jenkins"
  user_data         = file("user_data.sh")

  instance_name = "dev"
}