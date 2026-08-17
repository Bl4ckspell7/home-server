variable "hcloud_token" {
  description = "Hetzner Cloud API token with DNS write access. Injected via TF_VAR_hcloud_token by scripts/tf-dns.sh, which reads it from the sops-encrypted secrets.yml. Ephemeral, so it is never written to state."
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "domain" {
  description = "Apex domain name. The zone already exists at Hetzner and is adopted via the import block in import.tf, never created from scratch."
  type        = string
  default     = "bl4ckspell.de"
}

variable "dmarc_policy" {
  description = "DMARC record body for _dmarc. Defaults to a hard reject, matching the null MX + 'v=spf1 -all' pair: the domain neither sends nor receives mail, so anything claiming to be from it is forged."
  type        = string
  default     = "v=DMARC1; p=reject; adkim=s; aspf=s"
}

variable "record_ttl" {
  description = "TTL applied to every rrset in the zone."
  type        = number
  default     = 300
}
