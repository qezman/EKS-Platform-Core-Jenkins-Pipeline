variable "region" {
  description = "AWS region for all resources"
  default     = "us-east-1"
  type        = string
}

variable "project" {
  description = "Project name used as a prefix on all resources"
  default     = "eks-platform"
  type        = string
}

variable "environment" {
  description = "Environment name"
  default     = "dev"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to deploy into"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "node_desired_size" {
  description = "Desired number of EKS worker nodes"
  type        = number
  default     = 3
}

variable "node_max_size" {
  description = "Maximum number of EKS worker nodes"
  type        = number
  default     = 3
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "admin_cidr" {
  description = "Admin IP allowed to access the EKS API"
  type        = string
}

variable "jenkins_ssh_public_key" {
  description = "SSH public key for Jenkins EC2 access"
  type        = string
}
