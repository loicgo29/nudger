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
export LSCOLORS=ExFxBxDxCxegedabagacad  # Mac OS; sinon LS_COLORS pour Linux
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

# Prompt coloré
export PS1="\[\e[32m\]\u@\h\[\e[m\]:\[\e[34m\]\w\[\e[m\]\$ "
kubectl config set-context --current --namespace=nudger-xwiki
