provider "azurerm" {
  version = "=2.7.0"
  subscription_id = var.service_principal.subscription_id
  client_id = var.service_principal.client_id
  client_secret = var.service_principal.client_secret
  tenant_id = var.service_principal.tenant_id
  features {}
}

// common

resource "azurerm_resource_group" "aks" {
  name     = "${var.prefix}-aks"
  location = var.location
  tags = merge(var.tags, {
    description = "AKS Resource Group."
  })
}

// networking
resource "azurerm_virtual_network" "aks" {
  name                = "${var.prefix}-vnet"
  address_space       = [var.vnet_address_range]
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  tags = merge(var.tags, {
    description = "AKS VNet"
  })
}
resource "azurerm_subnet" "aks" {
  name                 = "${var.prefix}-subnet" 
  resource_group_name  = azurerm_resource_group.aks.name
  virtual_network_name = azurerm_virtual_network.aks.name
  address_prefix       = var.subnet_address_range
}

resource "azurerm_public_ip" "external_ingress" {
  name                = "${var.prefix}-ingress-ip"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  allocation_method   = "Static"
  domain_name_label   = var.prefix

  tags = merge(var.tags, {
    description = "AKS Public IP"
  })
}

// cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.prefix}-aks"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  node_resource_group = "${azurerm_resource_group.aks.name}-aks-nodes"
  dns_prefix          = azurerm_resource_group.aks.name

  default_node_pool {
    name           = "default"
    node_count     = var.node_count
    vm_size        = var.node_size
    vnet_subnet_id = azurerm_subnet.aks.id
  }

  service_principal {
    client_id     = var.service_principal.client_id
    client_secret = var.service_principal.client_secret
  }

  linux_profile {
    admin_username = var.admin.name
    ssh_key {
      key_data = var.admin.pubkey
    }
  }

  role_based_access_control {
    enabled = true
  }

  tags = merge(var.tags, {
    description = "AKS cluster."
  })

  depends_on = [azurerm_public_ip.external_ingress]
}
