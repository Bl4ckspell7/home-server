# Svr1

Setup code for my homeserver.

## Run

```bash
ansible-playbook -i inventory.yml playbook.yml [--limit hostname] [--tags tags]
```

## SSH Config:

```bash
Host my.srv1
    HostName #TOFILL
    User root
    IdentityFile ~/.ssh/ssh_bl4ckspell@proton.me
    IdentitiesOnly yes
```
