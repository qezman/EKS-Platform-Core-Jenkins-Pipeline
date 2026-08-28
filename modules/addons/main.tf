resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  chart            = "oci://ghcr.io/prometheus-community/charts/kube-prometheus-stack"
  version          = "88.3.0"
  namespace        = "monitoring"
  create_namespace = true
  timeout          = 600

  depends_on = [
    var.node_group_id
  ]
}
