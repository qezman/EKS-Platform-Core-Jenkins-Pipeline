terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = "eks-platform"

  default_tags {
    tags = {
      Project     = var.project
      ManagedBy   = "terraform"
      Environment = var.environment
    }
  }
}
