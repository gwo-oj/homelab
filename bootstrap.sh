#!/usr/bin/env bash
# First thing to run on a fresh Ubuntu install:
#
#   curl -fsSL https://raw.githubusercontent.com/gwo-oj/homelab/main/bootstrap.sh | bash
#
# Installs git and mise, clones the repo, installs the toolchain. Doesn't
# touch the cluster; run `task bootstrap` after restoring age.key.
set -euo pipefail

owner="${HOMELAB_USER:-gwo-oj}"
repo="${HOMELAB_REPO:-homelab}"
url="${HOMELAB_URL:-https://github.com/$owner/$repo.git}"
dest="${HOMELAB_DIR:-$HOME/repositories/$repo}"

log() { printf '\033[36m==>\033[0m %s\n' "$*"; }
die() { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }

[[ $EUID -ne 0 ]] || die "run as a normal user, not root"

missing=()
for p in git curl ca-certificates; do dpkg -s "$p" >/dev/null 2>&1 || missing+=("$p"); done
if (( ${#missing[@]} )); then
  log "installing ${missing[*]}"
  sudo apt-get update -qq
  sudo apt-get install -y -qq "${missing[@]}"
fi

if [[ -d "$dest/.git" ]]; then
  log "updating $dest"
  git -C "$dest" pull --ff-only
else
  log "cloning $url"
  mkdir -p "$(dirname "$dest")"
  git clone "$url" "$dest" || die "clone failed (private repo? set up auth first)"
fi
cd "$dest"

export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"
if ! command -v mise >/dev/null; then
  log "installing mise"
  curl -fsSL https://mise.run | sh
fi
grep -q 'mise activate bash' ~/.bashrc 2>/dev/null \
  || echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc

log "installing tools"
mise trust -q
mise install

cat <<EOF

Next:
  cd $dest && exec bash -l
EOF
if [[ ! -f age.key ]]; then
  cat <<'EOF'
  cp /path/to/backup/age.key .     # or: task sops:init  for a new setup
EOF
fi
cat <<'EOF'
  task ansible:deps
  task bootstrap
EOF
