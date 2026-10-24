#!/usr/bin/env bash
# Install Flux from the manifests committed under flux-system/. After this
# Flux manages itself from Git: upgrades are a re-export and a commit
# (task flux:export).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

dir="$ROOT/kubernetes/clusters/$(cfg cluster_name)/flux-system"

flux check --pre

# CRDs and controllers first; the sync objects need the CRDs to exist.
kubectl apply --server-side -f "$dir/gotk-components.yaml"
kubectl wait --for=condition=Established crd --all --timeout=2m >/dev/null
kubectl -n flux-system rollout status deploy --timeout=5m

kubectl apply --server-side -f "$dir/gotk-sync.yaml"
