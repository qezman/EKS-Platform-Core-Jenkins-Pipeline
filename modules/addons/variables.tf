variable "node_group_id" {
  description = "Used only to force addons to wait until the node group exists"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster the addons deploy into"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the cluster's IAM OIDC provider, for IRSA trust policies"
  type        = string
}

variable "oidc_provider_url" {
  description = "URL of the cluster's IAM OIDC provider, for IRSA trust policies"
  type        = string
}
