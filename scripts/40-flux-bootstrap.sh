#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

cluster="$(cfg cluster_name)"
owner="$(cfg github_user)"
repo="$(cfg github_repo)"
branch="$(cfg github_branch)"
token="$(secret github_token)"

flux check --pre

if [[ -n "$token" ]]; then
  GITHUB_TOKEN="$token" flux bootstrap github \
    --owner="$owner" \
    --repository="$repo" \
    --branch="$branch" \
    --path="kubernetes/clusters/$cluster" \
    --personal \
    --components-extra=image-reflector-controller,image-automation-controller
  exit 0
fi

# No token: read-only install from the public repo.
warn "no github_token, installing read-only"
flux install --components-extra=image-reflector-controller,image-automation-controller

kubectl apply -f - <<EOF
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: flux-system
  namespace: flux-system
spec:
  interval: 1m
  ref:
    branch: $branch
  url: https://github.com/$owner/$repo
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: flux-system
  namespace: flux-system
spec:
  interval: 10m
  path: ./kubernetes/clusters/$cluster
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-system
  decryption:
    provider: sops
    secretRef:
      name: sops-age
EOF
