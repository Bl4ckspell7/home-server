output "zone_id" {
  description = "Hetzner zone ID."
  value       = hcloud_zone.main.id
}

output "zone_name" {
  description = "Apex zone FQDN."
  value       = hcloud_zone.main.name
}
