variable "service_principal" {
  description = "Service Principal used by the AKS"
  type = object({
    client_id     = string
    client_secret = string
    subscription_id = string
    tenant_id = string
  })
}

variable "admin" {
    description = "Admin User to be set up on the nodes"
    type = object({
        name   = string
        pubkey = string
    })
}

variable "prefix" {
  description = "Resource prefix"
}

variable "location" {
  description = "The default location for the azure resources"
  default     = "westeurope"
}

variable "tags" {
  description = "Map of the common tags for all resources."
  type        = map
}

variable "node_count" {
  description = "Amount of nodes"
  default     = "1"
}

variable "node_size" {
  description = "Node Tier"
  default     = "Standard_B2ms"
}

variable "vnet_address_range" {
  description = "VNet address space"
  default     = "15.0.0.0/8"
}

variable "subnet_address_range" {
  description = "SubNet address space"
  default     = "15.0.0.0/16"
}

variable "dashboard_host" {
  type = string
  description = "Traefik dashboard domain"
}

variable "traefik_dashboard_htpaswd" {
  type = string
  description = "htpaswd generated credentials for the traefik dashboard ui"
}
