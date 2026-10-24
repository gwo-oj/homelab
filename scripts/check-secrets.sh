#!/usr/bin/env bash
# Pre-commit check for secrets that would leak into Git history.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

FAIL=0
fail() { printf '  \033[31mfail\033[0m %s\n' "$1"; FAIL=1; }

if git ls-files | grep -qE '(^|/)(age\.key|[^/]*\.agekey)$'; then
  fail "age key is tracked by git"
fi

# Split so this file doesn't match itself.
pat="AGE-SECRET-KEY""-1"
if files=$(git grep -lF "$pat" -- .) && [[ -n "$files" ]]; then
  fail "private key material in: $files"
fi

# *.sops.yaml files that were never encrypted. Excludes .sops.yaml itself.
while read -r f; do
  [[ -f "$f" ]] && ! grep -q '^sops:' "$f" && fail "not encrypted: $f"
done < <(git ls-files | grep -E '(^|/)[^/.][^/]*\.sops\.ya?ml$')

# Plain Secret manifests that should have been .sops.yaml
while read -r f; do
  [[ -f "$f" ]] || continue
  grep -qE '^kind:\s*Secret' "$f" && grep -qE '^\s*(data|stringData):' "$f" \
    && ! grep -q '^sops:' "$f" && fail "plaintext Secret: $f"
done < <(git ls-files 'kubernetes/*.yaml' | grep -v '\.sops\.yaml$')

if [[ -f age.key ]] && grep -q age1REPLACE_ME .sops.yaml; then
  fail ".sops.yaml still has the placeholder key"
fi

exit $FAIL
