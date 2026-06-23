#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/publish-docs.sh <patch|minor|major>

Builds and pushes the next Docusaurus image, updates the deployed image tag,
commits the tag bump, and deploys the docusaurus service.
EOF
}

bump="${1:-}"
case "${bump}" in
  patch | path | minor | major) ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

if [[ "${bump}" == "path" ]]; then
  bump="patch"
fi

for cmd in ansible-playbook docker git podman python3; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "Missing required command: ${cmd}" >&2
    exit 1
  fi
done

repo_root="$(git rev-parse --show-toplevel)"
cd "${repo_root}"

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree is not clean; commit or stash changes first." >&2
  git status --short >&2
  exit 1
fi

compose_file="roles/services/docusaurus/files/docker-compose.yml"
image="forgejo.bl4ckspell.freeddns.org/bl4ckspell/home-server-docs"
registry="forgejo.bl4ckspell.freeddns.org"

current_version="$(
  python3 - "${compose_file}" "${image}" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
image = sys.argv[2]
pattern = re.compile(rf"^\s*image:\s*{re.escape(image)}:(\d+\.\d+\.\d+)\s*$")

for line in path.read_text(encoding="utf-8").splitlines():
    match = pattern.match(line)
    if match:
        print(match.group(1))
        break
PY
)"

if [[ -z "${current_version}" ]]; then
  echo "Could not find current ${image} semver tag in ${compose_file}" >&2
  exit 1
fi

IFS=. read -r major minor patch <<<"${current_version}"

case "${bump}" in
  patch)
    patch=$((patch + 1))
    ;;
  minor)
    minor=$((minor + 1))
    patch=0
    ;;
  major)
    major=$((major + 1))
    minor=0
    patch=0
    ;;
esac

next_version="${major}.${minor}.${patch}"

echo "Publishing docs image ${image}:${current_version} -> ${image}:${next_version}"

cd documentation
podman login "${registry}"
podman build -f docker/Dockerfile -t "${image}:${next_version}" .
podman push "${image}:${next_version}"
cd ..

python3 - "${compose_file}" "${current_version}" "${next_version}" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
current = sys.argv[2]
next_version = sys.argv[3]
old = f"home-server-docs:{current}"
new = f"home-server-docs:{next_version}"

content = path.read_text(encoding="utf-8")
updated = content.replace(old, new, 1)

if updated == content:
    raise SystemExit(f"Could not replace {old} in {path}")

path.write_text(updated, encoding="utf-8")
PY

docker compose -f "${compose_file}" config --no-interpolate --quiet
ansible-playbook -i inventory.yml services.yml --syntax-check

git add "${compose_file}"
git commit -m "chore(docusaurus): bump docs image to ${next_version}"

ansible-playbook -i inventory.yml services.yml --tags docusaurus
