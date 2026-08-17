# The zone was created by Hetzner when the domain was bought, so it must be adopted
# rather than created — a bare `apply` without this would try to create a zone that
# already exists and fail.
#
# Safe to keep after the first apply: an import block whose target is already in
# state is a no-op.
import {
  to = hcloud_zone.main
  id = var.domain
}
