variable "aws_region" {
  description = "AWS region for S3 bucket"
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "Unique S3 bucket name for Terraform state"
  type        = string
  default     = "eks-platform-terraform-state-203637463799"
}

variable "lock_table_name" {
  description = "DynamoDB table name for Terraform state locking"
  type        = string
  default     = "eks-platform-Terraform-locks"
}
