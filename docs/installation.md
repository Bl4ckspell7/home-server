[← Back to README](../README.md)

---

## Installation Steps

## Bios

Perform BIOS update.

### Debian Install _(on server)_

- Leave root password empty.

- Partitions:

  - ESP: 500MB
  - boot: ext4 1.5GB
  - root: luks + lvm ext4

- GRUB Bootloader
- GNOME Desktop Environment
- SSH Server

### Grub _(on server)_

Mount ESP to `/efi` instead of `/boot/efi`:

1. Open "Disks", edit ESP Partition Mount Options.
2. `sudo grub-install --efi-directory=/efi`
3. `sudo update-grub`

### Roll out initial ssh key _(from remote)_

Login to user via `ssh user@IP` and password.

```bash
sudo -i
```

```bash
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKu1vcd8RLWKmfSJlb/i4HXmhs34T+exkmIEWx2yX+C7 bl4ckspell@proton.me" >> /root/.ssh/authorized_keys
```

```bash
chmod 600 /root/.ssh/authorized_keys
chown -R root:root /root/.ssh
```

### APT _(from remote)_

```bash
apt modernize-sources
```

### Automatic LUKS Decryption _(on server/from remote)_

Save your key to disk:

```bash
sudo -i
```

```bash
echo "my-very-long-passphrase" > /opt/luks.key
```

### Run Ansible Playbook _(from remote)_

Finally, run the playbook:

```bash
ansible-playbook -i inventory.yml playbook.yml [--tags tags]
```

### Cursor Theme

Manually set cursor theme using:

```bash
gsettings set org.gnome.desktop.interface cursor-theme Vimix-cursors
```

### Wake-on-LAN

1. Enable WOL in BIOS.

2. Find interface & MAC address:

```bash
ip addr show
```

Example: `enp5s0`, `xx:xx:xx:xx:xx:xx`

→ Set `wol_interface` in `server.yml` and run the Ansible role.

3. Verify WOL support:

```bash
ethtool enp5s0 | grep "Wake-on"
```

Output should contain `"g"`.

4. Wake the server:

```bash
wakeonlan xx:xx:xx:xx:xx:xx
```
