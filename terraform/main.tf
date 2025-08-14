provider "aws" {
  region = var.aws_region
}

# Networking Module
module "networking" {
  source = "./modules/networking"
}

# Security Module
module "security" {
  source = "./modules/security"
  vpc_id = module.networking.vpc_id
}

# Compute Module
module "compute" {
  source            = "./modules/compute"
  key_name          = var.key_name
  public_subnet_id  = module.networking.public_subnet_ids[0]
  private_subnet_id = module.networking.private_subnet_ids[0]
  access_sg_id      = module.security.normal_access_sg_id
}

# Application Module
module "app" {
  source              = "./modules/app"
  subscriber_email    = var.subscriber_email
  quarantine_sg_id    = module.security.quarantine_sg_id
  layer_zip_path      = var.layer_zip_path
  lambda_function_dir = var.lambda_function_dir
}
