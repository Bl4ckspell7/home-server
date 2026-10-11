terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.70.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "2.4.2"
    }
  }
  required_version = ">= 1.15.0"
}
