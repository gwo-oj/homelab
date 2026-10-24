# Sourced from ~/.bashrc

HOMELAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export HOMELAB_DIR

for d in "$HOME/.local/bin" "$HOME/.krew/bin" "$HOME/.local/share/mise/shims"; do
  [[ -d "$d" && ":$PATH:" != *":$d:"* ]] && PATH="$d:$PATH"
done
export PATH

[[ -f "$HOMELAB_DIR/kubeconfig" ]] && export KUBECONFIG="$HOMELAB_DIR/kubeconfig"
[[ -f "$HOMELAB_DIR/age.key"    ]] && export SOPS_AGE_KEY_FILE="$HOMELAB_DIR/age.key"

export EDITOR=nvim VISUAL=nvim
export LESS='-R -F -X -i'

# Cache completion scripts; generating kubectl's on every shell is slow.
_hl_completion() {
  local cmd=$1 cache="$HOME/.cache/bash-completion/$1"
  command -v "$cmd" >/dev/null || return
  if [[ ! -s "$cache" || "$(command -v "$cmd")" -nt "$cache" ]]; then
    mkdir -p "${cache%/*}"
    eval "$2" > "$cache" 2>/dev/null
  fi
  source "$cache"
}
_hl_completion kubectl   'kubectl completion bash'
_hl_completion helm      'helm completion bash'
_hl_completion flux      'flux completion bash'
_hl_completion task      'task --completion bash'
_hl_completion k9s       'k9s completion bash'
_hl_completion gh        'gh completion -s bash'
_hl_completion kustomize 'kustomize completion bash'
_hl_completion stern     'stern --completion bash'

alias k=kubectl
declare -F __start_kubectl >/dev/null && complete -o default -F __start_kubectl k

alias kns='kubectl ns'
alias kctx='kubectl ctx'
alias kg='kubectl get'
alias kgp='kubectl get pods -o wide'
alias kgpa='kubectl get pods -A -o wide'
alias kgn='kubectl get nodes -o wide'
alias kd='kubectl describe'
alias kl='kubectl logs -f --tail=100'
alias kex='kubectl exec -it'
alias ktop='kubectl resource-capacity --util --pods'
alias kbad='kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded'
alias kev='kubectl get events -A --sort-by=.lastTimestamp | tail -40'

alias fgk='flux get kustomizations -A'
alias fgh='flux get helmreleases -A'
alias ffail='flux get all -A --status-selector ready=false'
alias flog='flux logs -A --level=error --since=30m'

alias cdh='cd "$HOMELAB_DIR"'

if command -v eza >/dev/null; then
  alias ls='eza --group-directories-first'
  alias ll='eza -l --group-directories-first --git'
  alias la='eza -la --group-directories-first --git'
fi
command -v nvim >/dev/null && alias vim=nvim

# describe + previous logs for a failing pod
kwhy() {
  local ns=${2:-default}
  kubectl describe pod "$1" -n "$ns" | tail -30
  kubectl logs "$1" -n "$ns" --previous --tail=50 2>/dev/null
}

kdebug() {
  kubectl run "debug-$RANDOM" --rm -it --restart=Never \
    --image=nicolaka/netshoot -n "${1:-default}" -- bash
}

fwhy() {
  flux get kustomization "$1" -n flux-system
  kubectl describe kustomization "$1" -n flux-system | tail -30
}

command -v starship >/dev/null && eval "$(starship init bash)"
command -v direnv   >/dev/null && eval "$(direnv hook bash)"
command -v mise     >/dev/null && eval "$(mise activate bash)"

[[ -f /usr/share/doc/fzf/examples/key-bindings.bash ]] && . /usr/share/doc/fzf/examples/key-bindings.bash

HISTSIZE=100000
HISTFILESIZE=200000
HISTCONTROL=ignoreboth:erasedups
shopt -s histappend
PROMPT_COMMAND="history -a;${PROMPT_COMMAND:-}"
