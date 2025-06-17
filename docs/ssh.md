[← Back to README](../README.md)  

---

## SSH Config

```bash
Host svr1-local
    HostName # local ipv4 of server
    User root
    IdentityFile ~/.ssh/ssh_bl4ckspell@proton.me
    IdentitiesOnly yes

Host svr1-public-ipv4
    HostName # public ipv4 of router
    User root
    IdentityFile ~/.ssh/ssh_bl4ckspell@proton.me
    IdentitiesOnly yes

Host svr1-public-ipv6
    HostName # public ipv6 of router
    User root
    IdentityFile ~/.ssh/ssh_bl4ckspell@proton.me
    IdentitiesOnly yes
```
