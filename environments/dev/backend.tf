terraform {
  backend "s3" {
    bucket       = "eks-platform-terraform-state-203637463799"
    key          = "dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
    profile      = "eks-platform"
  }
}
