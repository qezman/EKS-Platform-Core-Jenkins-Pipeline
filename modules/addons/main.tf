# kube-prometheus-stack (Prometheus + Grafana)
resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  chart            = "oci://ghcr.io/prometheus-community/charts/kube-prometheus-stack"
  version          = "88.3.0"
  namespace        = "monitoring"
  create_namespace = true
  timeout = 1200

  values = [
    yamlencode({
      grafana = {
        persistence = {
          enabled          = true
          storageClassName = "gp3"
          size             = "5Gi"
        }
      }
      prometheus = {
        prometheusSpec = {
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "gp3"
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "20Gi"
                  }
                }
              }
            }
          }
        }
      }
    })
  ]

  depends_on = [
    var.node_group_id,
    kubernetes_storage_class_v1.gp3
  ]
}

# EBS CSI driver - IRSA role
# The driver's pods call the EC2 API (CreateVolume/AttachVolume/etc)
data "aws_iam_policy_document" "ebs_csi_driver_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ebs_csi_driver" {
  name               = "${var.cluster_name}-ebs-csi-driver"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_driver_assume_role.json

  tags = {
    Name = "${var.cluster_name}-ebs-csi-driver"
  }
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  role       = aws_iam_role.ebs_csi_driver.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# EBS CSI driver - EKS managed addon
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = var.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    var.node_group_id,
    aws_iam_role_policy_attachment.ebs_csi_driver
  ]

  tags = {
    Name = "${var.cluster_name}-ebs-csi-driver"
  }
}

# StorageClass backed by the CSI driver
resource "kubernetes_storage_class_v1" "gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner = "ebs.csi.aws.com"
  volume_binding_mode = "WaitForFirstConsumer"
  reclaim_policy      = "Retain"

  parameters = {
    type      = "gp3"
    encrypted = "true"
  }

  depends_on = [aws_eks_addon.ebs_csi_driver]
}
