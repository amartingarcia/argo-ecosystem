## K8S
resource "kubernetes_namespace" "argo_ecosystem" {
  metadata {
    name = "argo-ecosystem"
  }
}

resource "kubernetes_cluster_role" "argo_ecosystem_full" {
  metadata {
    name = "argo-ecosystem-full"
  }

  rule {
    api_groups = ["argoproj.io"]
    resources  = ["*"]
    verbs      = ["*"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "pods/log"]
    verbs      = ["*"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["jobs", "cronjobs"]
    verbs      = ["*"]
  }
}

resource "kubernetes_cluster_role_binding" "argo_ecosystem_full" {
  metadata {
    name = "argo-ecosystem-full"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.argo_ecosystem_full.metadata.0.name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = kubernetes_namespace.argo_ecosystem.metadata.0.name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = "default"
  }
}

## Argo Workflows
resource "helm_release" "argo_workflows" {
  name       = "argo-workflows"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-workflows"
  namespace  = kubernetes_namespace.argo_ecosystem.metadata.0.name
  atomic     = true

  values = [
    file("${path.module}/values/argo_workflows.yaml")
  ]

  wait = true
}

## Argo Events
resource "helm_release" "argo_events" {
  name       = "argo-events"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-events"
  namespace  = kubernetes_namespace.argo_ecosystem.metadata.0.name
  atomic     = true

  values = [
    file("${path.module}/values/argo_events.yaml")
  ]

  wait = true
}

## Argo CD
resource "helm_release" "argo_cd" {
  name       = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argo_ecosystem.metadata.0.name
  atomic     = true

  values = [
    file("${path.module}/values/argo_cd.yaml")
  ]

  wait = true
}

## Argo Rollouts
resource "helm_release" "argo_rollouts" {
  name       = "argo-rollouts"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-rollouts"
  namespace  = kubernetes_namespace.argo_ecosystem.metadata.0.name
  atomic     = true

  values = [
    file("${path.module}/values/argo_rollouts.yaml")
  ]

  wait = true
}