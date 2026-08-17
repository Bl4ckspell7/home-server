#!/usr/bin/env bash
# Terraform wrapper for the public DNS zone (terraform/dns).
#
# State is kept in the repo encrypted with sops/age, so this script brackets every
# Terraform run with decrypt/re-encrypt and shreds the plaintext afterwards. The
# cleanup runs from a trap, so the state is re-encrypted even when Terraform fails
# or the run is interrupted.
#
# Usage: scripts/tf-dns.sh init | plan | apply | destroy | ...
#
# NOTE: no state locking. Never run two of these concurrently.
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
tf_dir="${repo_root}/terraform/dns"
cd "${tf_dir}"

enc="terraform.tfstate.enc.json"
plain="terraform.tfstate"
secrets="secrets.yml"

if [[ ! -f "${secrets}" ]]; then
  echo "tf-dns.sh: missing ${tf_dir}/${secrets}" >&2
  echo "tf-dns.sh: create it with a single 'hcloud_token' key, then 'sops encrypt --in-place ${secrets}'" >&2
  exit 1
fi

cleanup() {
  local rc=$?
  if [[ -f "${plain}" ]]; then
    if sops encrypt --input-type json --output-type json "${plain}" >"${enc}.tmp"; then
      mv "${enc}.tmp" "${enc}"
      shred -u "${plain}" 2>/dev/null || rm -f "${plain}"
    else
      rm -f "${enc}.tmp"
      echo "tf-dns.sh: FAILED to re-encrypt state — ${tf_dir}/${plain} is still PLAINTEXT." >&2
      echo "tf-dns.sh: encrypt it by hand before committing anything." >&2
      return 1
    fi
  fi
  rm -f "${plain}.backup"
  return "${rc}"
}
trap cleanup EXIT

if [[ -f "${enc}" ]]; then
  sops decrypt --input-type json --output-type json "${enc}" >"${plain}"
fi

TF_VAR_hcloud_token="$(sops decrypt --extract '["hcloud_token"]' "${secrets}")"
export TF_VAR_hcloud_token

terraform "$@"
