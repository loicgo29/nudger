# ~/.bashrc

# Charger les alias
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Charger fzf si installé
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# Charger le profil Kubernetes si dispo
if [ -f ~/nudger/config-vm/profile_logo.sh ]; then
    source ~/nudger/config-vm/profile_logo.sh
fi

if command -v kubectl &> /dev/null; then
    # Définit le fichier où stocker la complétion
    COMPLETION_DIR="$HOME/.local/share/bash-completion/completions"
    KUBE_COMPLETION_FILE="$COMPLETION_DIR/kubectl"

    # Génère la complétion seulement si le binaire existe et que le fichier de complétion est plus ancien ou manquant
    if [[ ! -f "$KUBE_COMPLETION_FILE" || "$(which kubectl)" -nt "$KUBE_COMPLETION_FILE" ]]; then
        mkdir -p "$COMPLETION_DIR"
        kubectl completion bash > "$KUBE_COMPLETION_FILE" 2>/dev/null || echo "Warning: Échec de génération de la complétion kubectl" >&2
    fi

    # Charge la complétion
    if [[ -f "$KUBE_COMPLETION_FILE" ]]; then
        source "$KUBE_COMPLETION_FILE"
        # Configure la complétion pour l'alias 'k'
        complete -o default -F __start_kubectl k
    fi
fi
# --- fzf + Ctrl-R pour BASH ---
# Ne s'applique qu'à Bash
[ -n "$BASH_VERSION" ] || return 0

# Charge les bindings fournis par le paquet fzf (Ubuntu/Debian)
if [ -f /usr/share/doc/fzf/examples/key-bindings.bash ]; then
  . /usr/share/doc/fzf/examples/key-bindings.bash
fi

# Variante installateur (si ~/.fzf.bash existe)
[ -f ~/.fzf.bash ] && . ~/.fzf.bash

# Fallback : si Ctrl-R n'est pas lié, on crée un widget fzf pour l'historique
if ! bind -P 2>/dev/null | grep -q '"\C-r"'; then
  __fzf_history__() {
    local cmd
    cmd="$(HISTTIMEFORMAT= history | sed 's/^ *[0-9]\+ *//' | tac | fzf +s --height=40% --reverse)"
    [[ -n "$cmd" ]] || return
    READLINE_LINE="$cmd"
    READLINE_POINT=${#READLINE_LINE}
  }
  bind -x '"\C-r": __fzf_history__'
fi
