terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.69.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "2.4.1"
    }
  }
  required_version = ">= 1.15.0"
}
