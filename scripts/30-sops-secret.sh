#!/usr/bin/env bash
# Give Flux the age key so it can decrypt *.sops.yaml.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

[[ -f "$ROOT/age.key" ]] || die "age.key missing"

kubectl create namespace flux-system --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic sops-age -n flux-system \
  --from-file=age.agekey="$ROOT/age.key" \
  --dry-run=client -o yaml | kubectl apply -f -
