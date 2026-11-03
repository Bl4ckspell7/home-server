# Run via `bin/rails runner` while demo@dawarich.app exists (fresh install: it is
# the seeded, only admin). Login matches provider + uid first; an email match
# needs email_verified, which Authentik does not send, so the uid must be set.
sub = ENV.fetch("LINK_SUB")
email = ENV.fetch("LINK_EMAIL")
demo = User.unscoped.find_by(email: "demo@dawarich.app")
linked = User.unscoped.find_by(provider: "openid_connect", uid: sub)
pw = SecureRandom.hex(32)
if demo.nil?
  puts "ok: no demo user"
elsif linked.nil?
  demo.update!(email: email, provider: "openid_connect", uid: sub, password: pw, password_confirmation: pw)
  puts "changed: linked demo admin ##{demo.id}"
else
  # SSO login registered first: promote that account, retire the demo one (the
  # new email also stops the role from running this again).
  linked.update!(admin: true)
  demo.update!(email: "retired-demo@dawarich.app", admin: false, password: pw, password_confirmation: pw)
  puts "changed: promoted ##{linked.id}, retired demo ##{demo.id}"
end
