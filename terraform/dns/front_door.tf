# The IONOS VPS public IP is deliberately NOT committed to this repo — the same
# decision inventory.yml makes for `ansible_host: ionos-vps` ("resolves via
# ~/.ssh/config (keeps the IP out of git)"). Resolving it here from that identical
# ssh_config entry gives Ansible and Terraform one shared source of truth: if the
# IP ever changes, editing ~/.ssh/config is the only edit either tool needs.
#
# scripts/vps-ip.sh is a purely local lookup (`ssh -G`) — no network, no API call —
# and fails closed if the alias is missing or does not resolve to a bare IPv4.
data "external" "front_door" {
  program = ["${path.module}/../../scripts/vps-ip.sh"]
}

locals {
  front_door_ip = data.external.front_door.result.ip
}
