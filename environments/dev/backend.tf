terraform {
  backend "s3" {
    bucket       = "eks-platform-terraform-state-722965867897"
    key          = "dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
