#!/usr/bin/env bash
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

FAIL=0
fail() { bad "$1"; FAIL=1; }

for t in ansible-playbook kubectl flux sops age-keygen yq; do
  command -v "$t" >/dev/null && ok "$t" || fail "$t not found (run: mise install)"
done

ansible-galaxy collection list 2>/dev/null | grep -q community.sops \
  && ok "ansible collections" || fail "ansible collections missing (run: task ansible:deps)"

if [[ -f "$ROOT/age.key" ]]; then
  ok "age.key"
  grep -q age1REPLACE_ME "$ROOT/.sops.yaml" && fail ".sops.yaml has no public key (run: task sops:init)"
else
  fail "age.key missing (restore from backup, or task sops:init for a new setup)"
fi

if [[ -f "$SECRETS" ]]; then
  sops -d "$SECRETS" >/dev/null 2>&1 && ok "secrets decrypt" || fail "can't decrypt $SECRETS with this age.key"
else
  warn "no secrets.sops.yml (fine for a public repo without Tailscale)"
fi

ip="$(first_node_ip)"
ip -br addr | grep -qw "$ip" && ok "node IP $ip" || warn "$ip not on this host"

mem=$(awk '/MemTotal/ {printf "%d", $2/1024/1024}' /proc/meminfo)
(( mem >= 8 )) && ok "memory ${mem}G" || fail "memory ${mem}G, need 8G"

disk=$(df -BG --output=avail / | tail -1 | tr -dc 0-9)
(( disk >= 50 )) && ok "disk ${disk}G free" || fail "disk ${disk}G free, need 50G"

curl -sf -m 10 -o /dev/null https://get.k3s.io && ok "internet" || fail "can't reach get.k3s.io"

ip route get 1.1.1.1 2>/dev/null | grep -qE 'dev wl' && warn "default route is WiFi"

exit $FAIL
