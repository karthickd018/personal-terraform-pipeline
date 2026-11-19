module "ec2" {
  source = "../../../reusable-modules/ec2"

  name          = var.name
  ami_id        = var.ami_id
  instance_type = var.instance_type
  environment   = var.environment
  tags          = var.tags
}

output "instance_id" {
  value = module.ec2.instance_id
}

output "public_ip" {
  value = module.ec2.public_ip
}

output "private_ip" {
  value = module.ec2.private_ip
}
