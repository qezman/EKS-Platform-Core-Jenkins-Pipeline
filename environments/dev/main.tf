data "aws_caller_identity" "current" {}

module "vpc" {
  source             = "../../modules/vpc"
  project            = var.project
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}

module "eks" {
  source             = "../../modules/eks"
  project            = var.project
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  node_desired_size  = var.node_desired_size
  node_max_size      = var.node_max_size
  account_id         = var.account_id
  admin_cidr         = var.admin_cidr
}
