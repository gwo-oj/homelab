#!/usr/bin/env bash
# Shared helpers. Config lives in ansible/inventory/group_vars/all/ and is
# read here with yq/sops so the shell scripts and Ansible agree.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export ROOT
VARS="$ROOT/ansible/inventory/group_vars/all/main.yml"
SECRETS="$ROOT/ansible/inventory/group_vars/all/secrets.sops.yml"
HOSTS="$ROOT/ansible/inventory/hosts.yml"

export KUBECONFIG="${KUBECONFIG:-$ROOT/kubeconfig}"
export SOPS_AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-$ROOT/age.key}"

log()  { printf '\033[36m==>\033[0m %s\n' "$*"; }
ok()   { printf '  \033[32mok\033[0m   %s\n' "$*"; }
bad()  { printf '  \033[31mfail\033[0m %s\n' "$*"; }
warn() { printf '  \033[33mwarn\033[0m %s\n' "$*"; }
die()  { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }

cfg() { yq -r ".$1 // \"\"" "$VARS"; }

secret() {
  [[ -f "$SECRETS" ]] || return 0
  sops -d "$SECRETS" 2>/dev/null | yq -r ".$1 // \"\""
}

first_node_ip() {
  yq -r '.all.children.control_plane.hosts | to_entries | .[0].value.ansible_host' "$HOSTS"
}
