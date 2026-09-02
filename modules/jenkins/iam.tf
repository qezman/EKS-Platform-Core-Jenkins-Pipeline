data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "terraform_deployer" {
  statement {
    sid    = "S3StateBackend"
    effect = "Allow"
    actions = [
      "s3:CreateBucket",
      "s3:PutBucketVersioning",
      "s3:GetBucketVersioning",
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:DeleteObject",
      "s3:GetBucketPolicy",
      "s3:GetBucketAcl",
      "s3:GetBucketCORS",
      "s3:GetBucketWebsite",
      "s3:GetBucketLogging",
      "s3:GetBucketObjectLockConfiguration",
      "s3:GetBucketRequestPayment",
      "s3:GetReplicationConfiguration",
      "s3:GetLifecycleConfiguration",
      "s3:GetEncryptionConfiguration",
      "s3:PutEncryptionConfiguration",
      "s3:GetBucketPublicAccessBlock",
      "s3:PutBucketPublicAccessBlock",
      "s3:GetBucketTagging",
      "s3:PutBucketTagging",
      "s3:GetAccelerateConfiguration"
    ]
    resources = [
      "arn:aws:s3:::${var.terraform_state_bucket}",
      "arn:aws:s3:::${var.terraform_state_bucket}/*"
    ]
  }

  statement {
    sid    = "EC2VpcNetworking"
    effect = "Allow"
    actions = [
      "ec2:CreateVpc",
      "ec2:DeleteVpc",
      "ec2:DescribeVpcs",
      "ec2:DescribeVpcAttribute",
      "ec2:ModifyVpcAttribute",
      "ec2:CreateTags",
      "ec2:DeleteTags",
      "ec2:DescribeTags",
      "ec2:CreateSubnet",
      "ec2:DeleteSubnet",
      "ec2:DescribeSubnets",
      "ec2:ModifySubnetAttribute",
      "ec2:CreateInternetGateway",
      "ec2:DeleteInternetGateway",
      "ec2:DescribeInternetGateways",
      "ec2:AttachInternetGateway",
      "ec2:DetachInternetGateway",
      "ec2:AllocateAddress",
      "ec2:ReleaseAddress",
      "ec2:DescribeAddresses",
      "ec2:DescribeAddressesAttribute",
      "ec2:DescribeNetworkInterfaces",
      "ec2:CreateNatGateway",
      "ec2:DeleteNatGateway",
      "ec2:DescribeNatGateways",
      "ec2:CreateRouteTable",
      "ec2:DeleteRouteTable",
      "ec2:DescribeRouteTables",
      "ec2:CreateRoute",
      "ec2:DeleteRoute",
      "ec2:AssociateRouteTable",
      "ec2:DisassociateRouteTable",
      "ec2:ReplaceRouteTableAssociation",
      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSecurityGroupRules",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeImages",
      "ec2:DescribeInstanceCreditSpecifications",
      "ec2:ModifyInstanceCreditSpecification"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "IAMForEKSRoles"
    effect = "Allow"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:GetRole",
      "iam:ListAttachedRolePolicies",
      "iam:ListRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:GetRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:ListRoleTags",
      "iam:PassRole",
      "iam:CreateServiceLinkedRole",
      "iam:UpdateAssumeRolePolicy"
    ]
    resources = ["*"]
  }
  statement {
    sid     = "PassRoleScoped"
    effect  = "Allow"
    actions = ["iam:PassRole"]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project}-${var.environment}-eks-cluster-role",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project}-${var.environment}-eks-node-role"
    ]
  }

  statement {
    sid    = "EKSClusterAndNodes"
    effect = "Allow"
    actions = [
      "eks:CreateCluster",
      "eks:DeleteCluster",
      "eks:DescribeCluster",
      "eks:DescribeUpdate",
      "eks:TagResource",
      "eks:UntagResource",
      "eks:CreateNodegroup",
      "eks:DeleteNodegroup",
      "eks:DescribeNodegroup",
      "eks:CreateAccessEntry",
      "eks:DeleteAccessEntry",
      "eks:DescribeAccessEntry",
      "eks:ListAccessEntries",
      "eks:AssociateAccessPolicy",
      "eks:DisassociateAccessPolicy",
      "eks:ListAssociatedAccessPolicies",
      "eks:UpdateClusterConfig",
      "eks:UpdateClusterVersion",
      "eks:CreateAddon",
      "eks:DescribeAddon",
      "eks:DescribeAddonVersions",
      "eks:DeleteAddon",
      "eks:UpdateAddon"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "OIDCProvider"
    effect = "Allow"
    actions = [
      "iam:CreateOpenIDConnectProvider",
      "iam:DeleteOpenIDConnectProvider",
      "iam:GetOpenIDConnectProvider",
      "iam:TagOpenIDConnectProvider"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "IAMPolicyAndInstanceProfile"
    effect = "Allow"
    actions = [
      "iam:CreatePolicy",
      "iam:DeletePolicy",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicyVersions",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion",
      "iam:TagPolicy",
      "iam:ListPolicyTags",
      "iam:CreateInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:GetInstanceProfile",
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:TagInstanceProfile"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "EC2InstanceAndKeyPair"
    effect = "Allow"
    actions = [
      "ec2:RunInstances",
      "ec2:TerminateInstances",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceAttribute",
      "ec2:ModifyInstanceAttribute",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeImages",
      "ec2:DescribeVolumes",
      "ec2:AssociateIamInstanceProfile",
      "ec2:DisassociateIamInstanceProfile",
      "ec2:DescribeIamInstanceProfileAssociations",
      "ec2:CreateKeyPair",
      "ec2:DeleteKeyPair",
      "ec2:DescribeKeyPairs",
      "ec2:ImportKeyPair"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "terraform_deployer" {
  name   = "${var.project}-${var.environment}-terraform-deployer-policy"
  policy = data.aws_iam_policy_document.terraform_deployer.json
}

resource "aws_iam_role" "jenkins" {
  name = "${var.project}-${var.environment}-jenkins-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = {
    Name        = "${var.project}-${var.environment}-jenkins-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "jenkins_deployer_policy" {
  role       = aws_iam_role.jenkins.name
  policy_arn = aws_iam_policy.terraform_deployer.arn
}

resource "aws_iam_instance_profile" "jenkins" {
  name = "${var.project}-${var.environment}-jenkins-profile"
  role = aws_iam_role.jenkins.name
}
