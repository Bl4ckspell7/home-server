#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: scripts/fetch-icons.sh [ref]

Downloads the selfh.st icons served locally instead of from the jsdelivr CDN,
into two places:

  roles/services/homepage/files/icons/                  Homepage dashboard
  roles/services/authentik/files/application-icons/     Authentik app tiles

Both are committed so nothing is fetched from a CDN at runtime.

  ref   git ref of github.com/selfhst/icons to pull from (default: main).
        Pass a commit SHA to pin the icon set.

Only the icons listed in this script are written; other files in the target
directories are left alone (photon.png is a custom icon with no selfh.st entry).
After adding or removing an icon here, update the matching `icon: /icons/...`
entries in roles/services/homepage/files/config/, or the `icon:` value in
roles/services/authentik/defaults/main.yml.
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

homepage_dest="roles/services/homepage/files/icons"
authentik_dest="roles/services/authentik/files/application-icons"

# Icons sourced from https://github.com/selfhst/icons, as <name>.<ext>.
homepage_icons=(
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

# One tile per Authentik application (roles/services/authentik/defaults/main.yml).
# Authentik serves these from data/media/public/application-icons/ and the
# blueprint references them as the bare subpath `application-icons/<file>`.
authentik_icons=(
    cup-updates.svg
    dawarich.svg
    dockge.svg
    dockhand.png
    immich.svg
    linkwarden.svg
    paperless-ngx.svg
    pi-hole.svg
    uptime-kuma.svg
    vaultwarden.svg
)

fetch_set() {
    local dest="$1"
    shift
    mkdir -p "${dest}"
    echo "Fetching $# icons from selfhst/icons@${ref} into ${dest}/"

    local icon ext url tmp
    for icon in "$@"; do
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
}

fetch_set "${homepage_dest}" "${homepage_icons[@]}"
fetch_set "${authentik_dest}" "${authentik_icons[@]}"

echo "Done."
