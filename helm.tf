provider "helm" {
  version = "=1.1.0"
  kubernetes {
    load_config_file       = "false"
    host                   = azurerm_kubernetes_cluster.aks.kube_config.0.host

    client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
  }
}

data "helm_repository" "traefik" {
  name = "vbr"
  url  = "https://raw.githubusercontent.com/v-braun/traefik-helm-chart/master/"
}

locals{
  args = [
    "--providers.kubernetesingress",
    "--certificatesresolvers.default.acme.tlschallenge",
    "--certificatesresolvers.default.acme.email=${var.traefik_tls_letsencrypt_mail}",
    "--certificatesresolvers.default.acme.storage=/data/acme.json",
    "--certificatesresolvers.default.acme.caserver=${var.traefik_tls_letsencrypt_caserver}"
  ]
}

resource "helm_release" "traefik" {
  name      = "traefik"
  chart     = "vbr-traefik"
  repository = data.helm_repository.traefik.metadata[0].name
  version    = "1.0.1"

  set {
    name  = "traefik.persistence.enabled"
    value = "true"
  }
  set {
    name  = "traefik.additionalArguments"
    value = "{${join(",", local.args)}}"
  }
  set_string {
    name  = "traefik.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-resource-group"
    value = azurerm_resource_group.aks.name
  }
  set {
    name  = "traefik.service.spec.loadBalancerIP"
    value = azurerm_public_ip.external_ingress.ip_address
  }
  set {
    name  = "publicHost"
    value = var.dashboard_host
  }
  set {
    name  = "authSecretName"
    value = kubernetes_secret.dashboard_auth.metadata.0.name
  }
  # # there is a permission issue with managed disks
  # # see here: https://github.com/containous/traefik-helm-chart/issues/164
  # # new spawned pods will not start
  set {
    name  = "traefik.podSecurityContext.fsGroup"
    value = "null"
  }
  set {
    name  = "traefik.securityContext.readOnlyRootFilesystem"
    value = "false"
  }
  set {
    name  = "traefik.securityContext.runAsGroup"
    value = "0"
  }
  set {
    name  = "traefik.securityContext.runAsUser"
    value = "0"
  }
  set {
    name  = "traefik.securityContext.runAsNonRoot"
    value = "false"
  }
  
  depends_on = [kubernetes_cluster_role_binding.tiller, kubernetes_secret.dashboard_auth]
}
