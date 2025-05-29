# Setup VNC Server for remote desktop

## Server Setup

- set password:

```bash
sudo -u bl4ckspell vncpasswd
```

- stored in:
  `~/.config/tigervnc/passwd`

start vnc server:

```bash
systemctl status tigervncserver@:1.service
```

check if running:

```bash
systemctl status tigervncserver@:1.service
```

## Connecting

Remmina Client:

Server: `svr1-public-ipv6:5901`
User password: the vnc password

Enable SSH tunnel

- Same server at port 22
- via loopback address
- Authentication type: public key
