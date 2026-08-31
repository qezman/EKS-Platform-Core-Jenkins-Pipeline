variable "project" {
  description = "Name prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to launch the instance in"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID to launch the instance in"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for Jenkins"
  type        = string
  default     = "t3.micro"
}

variable "jenkins_ssh_public_key" {
  description = "SSH public key for Jenkins EC2 access"
  type        = string
}

variable "admin_cidr" {
  description = "Admin IP allowed to access the Jenkins EC2 instance"
  type        = string
}
