# aliases optionnels
[ -f ~/.bash_aliases ] && . ~/.bash_aliases

# kubectl completion + alias k
if command -v kubectl >/dev/null 2>&1; then
  COMPLETION_DIR="$HOME/.local/share/bash-completion/completions"
  KUBE_COMPLETION_FILE="$COMPLETION_DIR/kubectl"
  mkdir -p "$COMPLETION_DIR"
  if [[ ! -f "$KUBE_COMPLETION_FILE" || "$(command -v kubectl)" -nt "$KUBE_COMPLETION_FILE" ]]; then
    kubectl completion bash > "$KUBE_COMPLETION_FILE" 2>/dev/null || true
  fi
  [ -f "$KUBE_COMPLETION_FILE" ] && . "$KUBE_COMPLETION_FILE"
  alias k='kubectl'
  complete -o default -F __start_kubectl k
fi

# fzf (une seule source)
if [ -f /usr/share/doc/fzf/examples/key-bindings.bash ]; then
  . /usr/share/doc/fzf/examples/key-bindings.bash
elif [ -f ~/.fzf.bash ]; then
  . ~/.fzf.bash
fi

# Git minimal
if command -v git >/dev/null 2>&1; then
  alias g='git'; alias gs='git status -sb'
  alias glg='git log --oneline --graph --decorate --date=relative'
  alias gfa='git fetch --all --prune'
  alias gpl='git pull --ff-only'
  alias gsw='git switch'; alias gswc='git switch -c'
  alias grs='git restore'; alias grst='git restore --staged'
  alias gcm='git commit -m'; alias gca='git add -A && git commit -m'
  gpup() { git push -u origin "$(git branch --show-current)"; }
  _git_protected_regex='^(main|master|prod|production|release/.+)$'
  gpf() { local cur; cur="$(git branch --show-current 2>/dev/null)"; [[ "$cur" =~ $_git_protected_regex ]] && { echo "no force on $cur"; return 1; }; git push --force-with-lease "$@"; }
fi

# Starship (avant zoxide)
if command -v starship >/dev/null 2>&1; then
  export STARSHIP_CONFIG="/root/nudger/config-vm/starship.toml"
  eval "$(starship init bash)"
fi

# Zoxide sans eval/init : override cd + j/ji
# --- ZOXIDE : override cd + j/ji ---
if command -v zoxide >/dev/null 2>&1; then
  export _ZO_DATA_DIR="$HOME/.local/share/zoxide"

  cd() {
    if builtin cd "$@"; then
      zoxide add "$(pwd -L)" >/dev/null 2>&1 || true
    else
      return $?
    fi
  }

  j() {
    local d
    d="$(zoxide query -- "$@")" || return
    [ -d "$d" ] && builtin cd "$d"
  }

  ji() {
    local d
    d="$(zoxide query -i -- "$@")" || return
    [ -d "$d" ] && builtin cd "$d"
  }
fi
