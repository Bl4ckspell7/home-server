# Homepage

Port: `:3000` (exposed, no host binding)

- https://gethomepage.dev/
- https://github.com/gethomepage/homepage

## Icons

Icons are served locally, not from a CDN. Homepage's `sh-<name>.svg` shorthand makes every browser fetch the icon from jsdelivr on each page load; referencing `/icons/<name>.svg` instead serves it from the `./icons:/app/public/icons` mount.

Icon files live in `roles/services/homepage/files/icons/` and are deployed to `/opt/stacks/homepage/icons/` by the role.

Refresh them (or pull in new ones after editing the list inside the script):

```bash
scripts/fetch-homepage-icons.sh          # latest from selfhst/icons@main
scripts/fetch-homepage-icons.sh <sha>    # pin to a commit
```

Sourced from https://github.com/selfhst/icons. `photon.png` is a custom icon with no upstream entry — the script leaves it untouched.

When adding a service, add the icon name to the `icons` array in the script, re-run it, and reference the result as `icon: /icons/<name>.<ext>`.
