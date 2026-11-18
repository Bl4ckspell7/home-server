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

# Minecraft clients look this up before connecting, so mc.<domain> works without a
# port while the VPS listens off 25565. The target resolves via the wildcard A.
resource "hcloud_zone_rrset" "minecraft_srv" {
  zone    = hcloud_zone.main.name
  name    = "_minecraft._tcp.mc"
  type    = "SRV"
  ttl     = var.record_ttl
  records = [{ value = "0 5 ${var.minecraft_port} mc.${var.domain}.", comment = "Minecraft on the front-door" }]
}

# The SRV record makes mc.<domain> an empty non-terminal, which the "*" wildcard
# no longer covers (RFC 4592), so the SRV target needs its own A record.
resource "hcloud_zone_rrset" "minecraft_a" {
  zone    = hcloud_zone.main.name
  name    = "mc"
  type    = "A"
  ttl     = var.record_ttl
  records = [{ value = local.front_door_ip, comment = "Minecraft SRV target -> front-door" }]
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
