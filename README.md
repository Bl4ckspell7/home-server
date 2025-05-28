# Svr1

Setup code for my homeserver.

## SSH Config:

```bash
Host srv1
    HostName 192.168.178.117
    User root
    IdentityFile ~/.ssh/ssh_bl4ckspell@proton.me
    IdentitiesOnly yes
```

## Installation Steps

### Debian Install

Leave root password empty.

Partitions:

- ESP: 500MB
- boot: ext4 1.5GB
- root: luks + lvm ext4

GRUB Bootloader
GNOME Desktop Environment
SSH Server

### Grub

Mount ESP to `/efi` instead of `/boot/efi`:

1. Open "Disks", edit ESP Partition Mount Options.
2. `sudo grub-install --efi-directory=/efi`
3. `sudo update-grub`

### Roll out initial ssh key

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

### Automatic LUKS Decryption

### Run Ansible Playbook

Finally, run the playbook:

```bash
ansible-playbook -i inventory.yml playbook.yml [--limit hostname] [--tags tags]
```
