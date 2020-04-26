provider "kubernetes" {
  version = "=1.11"
  host = azurerm_kubernetes_cluster.aks.kube_config.0.host

  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
}

resource "kubernetes_service_account" "tiller" {
  metadata {
    name      = "tiller"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "tiller" {
  metadata {
    name = kubernetes_service_account.tiller.metadata.0.name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.tiller.metadata.0.name
    namespace = "kube-system"
  }
}

resource "kubernetes_secret" "dashboard_auth" {
  metadata {
    name      = "traefik-dashboard-secret"
  }

  data = {
    password = var.traefik_dashboard_htpaswd
  }

  type = "kubernetes.io/basic-auth"
}
