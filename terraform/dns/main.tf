resource "hcloud_zone" "main" {
  name = var.domain
  mode = "primary"

  # Both of these are optional+computed, so leaving them out lets the provider
  # decide: delete_protection would go to "known after apply" (the zone has it ON
  # today) and ttl would silently drop to the provider default. Pin them to the
  # values the zone already has so applying this config only changes what the
  # migration actually needs.
  delete_protection = true

  # Zone-level default TTL, inert in practice: every rrset below sets its own.
  ttl = 7200

  labels = {
    managed_by = "terraform"
  }
}

# Apex + wildcard both point at the VPS front-door. The wildcard is the whole point
# of this zone: every service is reached through the same Caddy front-door, which
# mints a per-hostname cert on demand, so adding a service never touches DNS.
resource "hcloud_zone_rrset" "apex_a" {
  zone    = hcloud_zone.main.name
  name    = "@"
  type    = "A"
  ttl     = var.record_ttl
  records = [{ value = local.front_door_ip, comment = "IONOS VPS front-door" }]
}

resource "hcloud_zone_rrset" "wildcard_a" {
  zone    = hcloud_zone.main.name
  name    = "*"
  type    = "A"
  ttl     = var.record_ttl
  records = [{ value = local.front_door_ip, comment = "all services -> front-door" }]
}

# Anti-spoofing trio. The domain neither sends nor receives mail, so say so
# explicitly rather than leaving the gap Hetzner's stock "?all" SPF left open.
resource "hcloud_zone_rrset" "null_mx" {
  zone    = hcloud_zone.main.name
  name    = "@"
  type    = "MX"
  ttl     = var.record_ttl
  records = [{ value = "0 .", comment = "RFC 7505 null MX - receives no mail" }]
}

resource "hcloud_zone_rrset" "spf" {
  zone    = hcloud_zone.main.name
  name    = "@"
  type    = "TXT"
  ttl     = var.record_ttl
  records = [{ value = "\"v=spf1 -all\"", comment = "sends no mail" }]
}

resource "hcloud_zone_rrset" "dmarc" {
  zone    = hcloud_zone.main.name
  name    = "_dmarc"
  type    = "TXT"
  ttl     = var.record_ttl
  records = [{ value = "\"${var.dmarc_policy}\"", comment = "reject anything claiming this domain" }]
}
