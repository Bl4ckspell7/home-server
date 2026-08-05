#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: scripts/fetch-homepage-icons.sh [ref]

Downloads the selfh.st icons used by the Homepage dashboard into
roles/services/homepage/files/icons/, so the browser serves them locally
instead of fetching from the jsdelivr CDN on every page load.

  ref   git ref of github.com/selfhst/icons to pull from (default: main).
        Pass a commit SHA to pin the icon set.

Only the icons listed in this script are written; other files in the target
directory are left alone (photon.png is a custom icon with no selfh.st entry).
After adding or removing an icon here, update the matching `icon: /icons/...`
entries in roles/services/homepage/files/config/.
EOF
}

ref="${1:-main}"
case "${ref}" in
    -h | --help)
        usage
        exit 0
        ;;
esac

for cmd in curl git; do
    if ! command -v "${cmd}" >/dev/null 2>&1; then
        echo "Missing required command: ${cmd}" >&2
        exit 1
    fi
done

repo_root="$(git rev-parse --show-toplevel)"
cd "${repo_root}"

dest="roles/services/homepage/files/icons"

# Icons sourced from https://github.com/selfhst/icons, as <name>.<ext>.
icons=(
    anubis.png
    authentik.svg
    backrest.svg
    caddy.svg
    cup-updates.svg
    dawarich.svg
    ddns-updater.svg
    dockge.svg
    dockhand.png
    docusaurus.svg
    forgejo.svg
    github-light.svg
    immich.svg
    jellyfin.svg
    linkwarden.svg
    mastodon.svg
    matrix-light.svg
    ollama.svg
    paperless-ngx.svg
    pi-hole.svg
    proton-mail.svg
    radicale.svg
    steam.svg
    uptime-kuma.svg
    vaultwarden.svg
    youtube.svg
)

mkdir -p "${dest}"

echo "Fetching ${#icons[@]} icons from selfhst/icons@${ref} into ${dest}/"

for icon in "${icons[@]}"; do
    ext="${icon##*.}"
    url="https://cdn.jsdelivr.net/gh/selfhst/icons@${ref}/${ext}/${icon}"
    tmp="$(mktemp)"

    if ! curl -fsSL --retry 3 -o "${tmp}" "${url}"; then
        rm -f "${tmp}"
        echo "Failed to download ${url}" >&2
        exit 1
    fi

    install -m 0644 "${tmp}" "${dest}/${icon}"
    rm -f "${tmp}"
    echo "  ${icon}"
done

echo "Done."
