#!/usr/bin/env bash
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

layers=(flux-system flux-config infrastructure-controllers infrastructure-config observability apps)
timeout="${WAIT_TIMEOUT:-15m}"
failed=()

flux reconcile source git flux-system -n flux-system || true

for k in "${layers[@]}"; do
  kubectl get kustomization "$k" -n flux-system >/dev/null 2>&1 || continue
  log "waiting for $k"
  if flux reconcile kustomization "$k" -n flux-system --timeout="$timeout" >/dev/null 2>&1; then
    ok "$k"
  else
    bad "$k"; failed+=("$k")
  fi
done

flux get kustomizations -A

if (( ${#failed[@]} )); then
  echo
  flux get all -A --status-selector ready=false
  flux logs -A --level=error --since=10m | tail -40
  exit 1
fi
