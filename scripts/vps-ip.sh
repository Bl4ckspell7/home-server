#!/usr/bin/env bash
# Resolve the IONOS VPS public IPv4 from ~/.ssh/config and emit it as JSON for
# Terraform's `external` data source (terraform/dns/front_door.tf).
#
# The IP is deliberately not committed anywhere in this repo; ~/.ssh/config is the
# single source of truth, shared with Ansible via `ansible_host: ionos-vps` in
# inventory.yml. `ssh -G` only parses the config — it opens no connection.
set -euo pipefail

host="${1:-ionos-vps}"

if ! ip="$(ssh -G "${host}" 2>/dev/null | awk '/^hostname /{print $2; exit}')"; then
  echo "vps-ip.sh: failed to read ssh config for host '${host}'" >&2
  exit 1
fi

if [[ ! "${ip}" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
  echo "vps-ip.sh: '${host}' did not resolve to a bare IPv4 (got: '${ip}')" >&2
  echo "vps-ip.sh: check the HostName of the '${host}' entry in ~/.ssh/config" >&2
  exit 1
fi

printf '{"ip":"%s"}' "${ip}"
