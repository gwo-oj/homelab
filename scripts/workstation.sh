#!/usr/bin/env bash
# Install CLI tools and link dotfiles. Safe to re-run. Never overwrites
# existing config; it only appends a source line or symlinks into dotfiles/.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
DOT="$ROOT/dotfiles"

log "apt packages"
pkgs=(neovim tmux htop btop iotop-c ncdu duf sysstat fzf fd-find bat ripgrep
      tree eza build-essential git curl wget unzip jq bash-completion direnv
      shellcheck dnsutils net-tools tcpdump nmap socat)
sudo apt-get update -qq
missing=()
for p in "${pkgs[@]}"; do
  dpkg -s "$p" >/dev/null 2>&1 && continue
  sudo apt-get install -y -qq --no-install-recommends "$p" >/dev/null 2>&1 || missing+=("$p")
done
(( ${#missing[@]} )) && warn "not available: ${missing[*]}"

# Ubuntu ships these under different names
mkdir -p "$HOME/.local/bin"
[[ -x /usr/bin/batcat ]] && ln -sf /usr/bin/batcat "$HOME/.local/bin/bat"
[[ -x /usr/bin/fdfind ]] && ln -sf /usr/bin/fdfind "$HOME/.local/bin/fd"

log "mise"
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"
command -v mise >/dev/null || curl -fsSL https://mise.run | sh
(cd "$ROOT" && mise trust -q && mise install) || warn "mise install failed"

log "krew"
export PATH="$HOME/.krew/bin:$PATH"
if [[ ! -x "$HOME/.krew/bin/kubectl-krew" ]]; then
  tmp="$(mktemp -d)"
  arch="$(uname -m | sed -e s/x86_64/amd64/ -e s/aarch64/arm64/)"
  curl -fsSL "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew-linux_${arch}.tar.gz" \
    | tar -xz -C "$tmp" && "$tmp/krew-linux_${arch}" install krew >/dev/null
  rm -rf "$tmp"
fi
for p in ctx ns neat tree view-secret get-all images outdated resource-capacity df-pv; do
  kubectl krew list 2>/dev/null | grep -qx "$p" || kubectl krew install "$p" >/dev/null 2>&1 || warn "krew $p"
done

log "dotfiles"
marker="# homelab dotfiles"
if ! grep -qF "$marker" "$HOME/.bashrc"; then
  printf '\n%s\n[ -f "%s" ] && . "%s"\n' "$marker" "$DOT/bash/homelab.bash" "$DOT/bash/homelab.bash" >> "$HOME/.bashrc"
  ok ".bashrc"
fi

if [[ -e "$HOME/.config/nvim" && ! -L "$HOME/.config/nvim" ]]; then
  warn "~/.config/nvim exists, skipping"
else
  ln -sfn "$DOT/nvim" "$HOME/.config/nvim" && ok "nvim"
fi

if [[ -f "$HOME/.tmux.conf" && ! -L "$HOME/.tmux.conf" ]]; then
  grep -qF homelab.tmux.conf "$HOME/.tmux.conf" \
    || printf '\nsource-file -q %s\n' "$DOT/tmux/homelab.tmux.conf" >> "$HOME/.tmux.conf"
else
  ln -sfn "$DOT/tmux/homelab.tmux.conf" "$HOME/.tmux.conf"
fi
ok "tmux"

command -v starship >/dev/null || curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin" >/dev/null
if [[ -e "$HOME/.config/starship.toml" && ! -L "$HOME/.config/starship.toml" ]]; then
  warn "starship.toml exists, skipping"
else
  ln -sfn "$DOT/starship.toml" "$HOME/.config/starship.toml" && ok "starship"
fi

echo
echo "Done. Open a new shell or run: exec bash -l"
