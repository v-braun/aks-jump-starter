# aks-jump-starter
> Terraform module to scaffold an AKS (Azure Kubernetes Service) instance with a pre-installed Traefik

By [v-braun - viktor-braun.de](https://viktor-braun.de).

[![](https://img.shields.io/github/license/v-braun/aks-jump-starter.svg?style=flat-square)](https://github.com/v-braun/aks-jump-starter/blob/master/LICENSE)
![PR welcome](https://img.shields.io/badge/PR-welcome-green.svg?style=flat-square)

<p align="center">
<img width="90%" src="https://github.com/v-braun/aks-jump-starter/blob/master/resources/aks-jump-starter.png?raw=true" alt="aks-jump-starter" />
</p>


## Description
This Terraform Module bootstraps an AKS (Azure Kubernetes Service) with an installed Traefik Ingress and a public available Traefik Dashboard.  


## Installation

To install this module, simply reference this repo
```terraform
module "aks" {
  source = "github.com/v-braun/aks-jump-starter"

  # your configurations here ...
}
```


## Usage
See the parameters of this module below

```terraform
module "aks" {
  source = "github.com/v-braun/aks-jump-starter"

  # all azure resources will be prefixed with this value
  prefix = var.prefix
  
  # default azure resources location
  location = "westeurope"
  
  # additional tags added to all resource (as a map)
  tags = var.tags

  # AKS node count
  node_count = "1"
  
  # AKS node pricing tier
  node_size = "Standard_B2ms"
  
  # AKS has to be connected to a subnet within a VNet
  # specify here the address ranges
  vnet_address_range = "15.0.0.0/8"
  subnet_address_range = "15.0.0.0/16"
  
  # service principal credentials
  service_principal = {
    client_id = var.client_id
    client_secret = var.client_secret
    subscription_id = var.subscription_id
    tenant_id = var.tenant_id
  }

  # scale set admin user name and pub key
  admin = {
    name   = var.admin_user
    pubkey = file(var.admin_pubkey)
  }

  # domain to the traefik dashboard (traefik.your-domain.here)
  dashboard_host = var.dashboard_host
  
  # htpaswd generated basic auth ky (usr:pwdhash) for the dashboard authentication
  traefik_dashboard_htpaswd = var.traefik_dashboard_htpaswd

  # email adress that should be used for let's encrypt
  tls_letsencrypt_mail = "foo@you.com"

  # the let's encrypt server (default is the staging server)
  # set it to: https://acme-v02.api.letsencrypt.org/directory to use the production server
  tls_letsencrypt_caserver = "https://acme-staging-v02.api.letsencrypt.org/directory"
}
```


## Authors

![image](https://avatars3.githubusercontent.com/u/4738210?v=3&amp;s=50)  
[v-braun](https://github.com/v-braun/)



## Contributing

Make sure to read these guides before getting started:
- [Contribution Guidelines](https://github.com/v-braun/aks-jump-starter/blob/master/CONTRIBUTING.md)
- [Code of Conduct](https://github.com/v-braun/aks-jump-starter/blob/master/CODE_OF_CONDUCT.md)

## License
**aks-jump-starter** is available under the MIT License. See [LICENSE](https://github.com/v-braun/aks-jump-starter/blob/master/LICENSE) for details.
