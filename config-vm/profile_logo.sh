#!/bin/bash

###############################################################
#  SCRIPT BASH AVEC SYNTAXE CORRECTE
###############################################################

# Installation de bash (normalement déjà présent)
if ! command -v bash >/dev/null; then
    echo "🔹 Installation de bash..."
    sudo apt update && sudo apt install -y bash
fi

# ASCII art + configuration
clear

# Configuration de l'environnement
export KUBECONFIG="/home/vagrant/.k0s/kubeconfig"

# Configuration de l'historique (équivalent Bash)
HISTCONTROL=ignoredups:erasedups
HISTSIZE=100000
HISTFILESIZE=200000

# Alias
alias ll='ls -laFh --color=auto'
alias la='ls -A'
alias l='ls -larth'
alias gl='git log'
alias gst='git status'
alias gg='git log --oneline --all --graph --name-status'
alias s='sudo -s'
alias h='helm'
alias k='kubectl'
alias kcc='kubectl config current-context'
alias kg='kubectl get'
alias kga='kubectl get all --all-namespaces'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kn='kubens'
alias ksgp='kubectl get pods -n kube-system'
alias kss='kubectl get services -n kube-system'
alias kuc='kubectl config use-context'
alias kx='kubectx'
alias vu='vagrant up'


echo "✅ Environnement bash complètement configuré !"
#!/bin/bash
# Fichier : ~/profile_logo.sh
# Rôle : Affiche un logo et configure l'env Kubernetes pour Vagrant

# Couleur verte
echo -e '\033[0;32m'
cat << "EOF"
██╗░░░░░░█████╗░░██████╗░░█████╗░
██║░░░░░██╔══██╗██╔════╝░██╔══██╗
██║░░░░░██║░░██║██║░░██╗░██║░░██║
██║░░░░░██║░░██║██║░░╚██╗██║░░██║
███████╗╚█████╔╝╚██████╔╝╚█████╔╝
╚══════╝░╚════╝░░╚═════╝░░╚════╝░
EOF
echo -e '\033[0m'

# Variables d'env spécifiques à Kubernetes
export KUBECONFIG="/home/vagrant/.k0s/kubeconfig"

# Historique optimisé pour Bash
HISTCONTROL=ignoredups:erasedups
HISTSIZE=100000
HISTFILESIZE=200000

# Alias Kubernetes
alias k='kubectl'
alias kcc='kubectl config current-context'
alias kg='kubectl get'
alias kga='kubectl get all --all-namespaces'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias ksgp='kubectl get pods -n kube-system'
alias kss='kubectl get services -n kube-system'
alias kuc='kubectl config use-context'

# Autres alias utiles
alias ll='ls -laFh --color=auto'
alias la='ls -A'
alias l='ls -larth'
alias gl='git log'
alias gst='git status'
alias gg='git log --oneline --all --graph --name-status'
alias s='sudo -s'
alias vu='vagrant up'

# Configuration fiable de la complétion kubectl
if command -v kubectl &>/dev/null; then
    # Création du répertoire si inexistant
    COMPLETION_DIR="$HOME/.local/share/bash-completion/completions"
    mkdir -p "$COMPLETION_DIR"
    
    # Génération du fichier de complétion
    KUBE_COMPLETION_FILE="$COMPLETION_DIR/kubectl"
    kubectl completion bash > "$KUBE_COMPLETION_FILE" 2>/dev/null
    
    # Chargement sécurisé
    if [[ -f "$KUBE_COMPLETION_FILE" ]]; then
        source "$KUBE_COMPLETION_FILE"
        # Alias standard avec complétion
        alias k=kubectl
        complete -o default -F __start_kubectl k
        
        # Alias supplémentaires utiles
        alias kg='kubectl get'
        alias kd='kubectl describe'
        alias kn='kubectl config set-context --current --namespace'
    else
        echo "Warning: Échec de génération de la complétion kubectl" >&2
    fi
fi
echo "✅ Environnement Kubernetes prêt !"

