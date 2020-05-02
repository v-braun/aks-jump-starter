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
  name = "traefik"
  url  = "https://containous.github.io/traefik-helm-chart"
}

locals{
  args = [
    # "--providers.kubernetesingress",
    "--certificatesresolvers.letsencrypt.acme.tlschallenge",
    "--certificatesresolvers.letsencrypt.acme.email=${var.traefik_tls_letsencrypt_mail}",
    "--certificatesresolvers.letsencrypt.acme.storage=/data/acme.json",
    "--certificatesresolvers.letsencrypt.acme.caserver=${var.traefik_tls_letsencrypt_caserver}"
  ]
}

resource "helm_release" "traefik" {
  name      = "traefik"
  chart     = "traefik/traefik"
  repository = data.helm_repository.traefik.metadata[0].name
  version    = "8.1.0"

  set {
    name  = "persistence.enabled"
    value = "true"
  }
  set {
    name  = "additionalArguments"
    value = "{${join(",", local.args)}}"
  }
  set_string {
    name  = "service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-resource-group"
    value = azurerm_resource_group.aks.name
  }
  set {
    name  = "service.spec.loadBalancerIP"
    value = azurerm_public_ip.external_ingress.ip_address
  }

  # # there is a permission issue with managed disks
  # # see here: https://github.com/containous/traefik-helm-chart/issues/164
  # # new spawned pods will not start
  set {
    name  = "podSecurityContext.fsGroup"
    value = "null"
  }
  set {
    name  = "securityContext.readOnlyRootFilesystem"
    value = "false"
  }
  set {
    name  = "securityContext.runAsGroup"
    value = "0"
  }
  set {
    name  = "securityContext.runAsUser"
    value = "0"
  }
  set {
    name  = "securityContext.runAsNonRoot"
    value = "false"
  }
  
  depends_on = [kubernetes_cluster_role_binding.tiller, kubernetes_secret.dashboard_auth]
}

# traefik need a while to bootup and should be started before deploy 
# ingressroutes otherwise the letsencrypt generation will fail
resource "null_resource" "wait_traefik" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "sleep 1m"
  }

  depends_on = [helm_release.traefik]
}


data "helm_repository" "ingress_route" {
  name = "traefik-ingress-route"
  url  = "https://raw.githubusercontent.com/v-braun/traefik-ingress-route-chart/master/ingress-route/"
}
data "helm_repository" "middleware" {
  name = "traefik-middleware"
  url  = "https://raw.githubusercontent.com/v-braun/traefik-middleware-chart/master/traefik-middleware/"
}

resource "helm_release" "traefik_dashboard" {
  name      = "dashboard"
  chart     = "ingress-route"
  repository = data.helm_repository.ingress_route.metadata[0].name
  version    = "1.0.0"

  values = [
<<EOF
spec:
  entryPoints:
    - websecure
  routes:
  - match: Host(`${var.dashboard_host}`)
    kind: Rule
    services:
    - name: api@internal
      kind: TraefikService
  tls:
    certResolver: letsencrypt
EOF
  ]

  depends_on = [null_resource.wait_traefik]
}

  # set {
  #   name  = "publicHost"
  #   value = var.dashboard_host
  # }
  # set {
  #   name  = "authSecretName"
  #   value = kubernetes_secret.dashboard_auth.metadata.0.name
  # }