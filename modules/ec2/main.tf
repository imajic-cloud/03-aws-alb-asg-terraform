data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "this" {
  ami             = data.aws_ami.latest_amazon_linux.id
  instance_type   = var.instance_type
  vpc_security_group_ids = [var.security_group_id]

  key_name  = var.key_name
  user_data = var.user_data

  tags = {
    Name = var.instance_name
  }
}