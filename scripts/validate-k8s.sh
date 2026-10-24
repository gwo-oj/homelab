#!/usr/bin/env bash
# Build every Flux kustomization path, substitute ${VARS} from
# cluster-settings the way Flux does, and validate with kubeconform.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

settings=kubernetes/flux/cluster-settings.yaml
while IFS='=' read -r k v; do export "$k=$v"; done \
  < <(yq -r '.data | to_entries | .[] | .key + "=" + .value' "$settings")

catalog='https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json'

# Paths that Flux Kustomizations point at
paths=$(yq -r 'select(.kind == "Kustomization") | .spec.path' kubernetes/clusters/*/*.yaml | grep -v '^---$' | sed 's|^\./||')

fail=0
for p in $paths; do
  out=$(kustomize build "$p" 2>&1 | flux envsubst --strict 2>&1 \
    | kubeconform -strict -summary -schema-location default -schema-location "$catalog" 2>&1)
  if [[ $? -ne 0 ]]; then
    echo "FAIL $p"; echo "$out" | sed 's/^/     /'; fail=1
  else
    echo "ok   $p  ($(echo "$out" | grep -o 'Valid: [0-9]*'))"
  fi
done
exit $fail
