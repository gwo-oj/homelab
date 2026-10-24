# homelab

Single-node k3s cluster running on an old laptop, managed with Ansible and Flux.
The plan is to grow it to three nodes eventually.

```
ansible/      host setup: packages, kernel params, static IP, k3s
kubernetes/   everything Flux deploys
scripts/      bootstrap glue that didn't fit in Ansible
dotfiles/     shell, nvim, tmux config for working on this repo
```

## Rebuilding from scratch

On a fresh Ubuntu install:

```sh
curl -fsSL https://raw.githubusercontent.com/gwo-oj/homelab/main/bootstrap.sh | bash
cd ~/repositories/homelab
cp /path/to/backup/age.key .
task bootstrap
```

`bootstrap.sh` installs git and mise, clones the repo, and installs the
toolchain. `task bootstrap` runs Ansible, sets up k3s, and bootstraps Flux.

The age key is the one thing that isn't in the repo. Without it the SOPS
secrets can't be decrypted. Keep a copy somewhere other than this machine.

## Day to day

Most changes go through Git: edit something under `kubernetes/`, push, and
Flux picks it up within a minute. Changes made with `kubectl` directly get
reverted on the next reconcile.

Host-level changes (sysctl, packages, adding a node) go through Ansible:

```sh
task ansible:check   # dry run
task ansible:apply
```

Run `task` to see everything else. The ones I use most:

```sh
task status
task reconcile
task validate
task secrets:edit
```

## Secrets

Encrypted with [SOPS](https://github.com/getsops/sops) and age, committed
alongside everything else. Only values under `data`/`stringData` are encrypted
in Kubernetes secrets, so diffs stay readable.

`task hooks:install` adds a pre-commit hook that blocks unencrypted secrets.

## Hardware

| | |
|---|---|
| CPU | i7-8565U (4c/8t, 15W) |
| RAM | 16 GB |
| Disk | 512 GB NVMe |
| Network | WiFi for now, wired adapter pending |
