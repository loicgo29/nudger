#!/bin/zsh

###############################################################
#  SCRIPT ZSH COMPLET AVEC SYNTAXE CORRECTE
###############################################################

# Installation de zsh si nécessaire
if ! command -v zsh >/dev/null; then
    echo "🔹 Installation de zsh..."
    sudo apt update && sudo apt install -y zsh
fi

# Basculement immédiat vers zsh
if [ "$(basename "$SHELL")" != "zsh" ]; then
    echo "🔹 Passage en zsh..."
    exec zsh -l -c "
        clear
        echo -e '\\033[0;32m'
        echo '
██╗░░░░░░█████╗░░██████╗░░█████╗░
██║░░░░░██╔══██╗██╔════╝░██╔══██╗
██║░░░░░██║░░██║██║░░██╗░██║░░██║
██║░░░░░██║░░██║██║░░╚██╗██║░░██║
███████╗╚█████╔╝╚██████╔╝╚█████╔╝
╚══════╝░╚════╝░░╚═════╝░░╚════╝░
'

        # Configuration de l'environnement
        export KUBECONFIG=\"/home/vagrant/.k0s/kubeconfig\"

        # Configuration de l'historique
        setopt HIST_IGNORE_ALL_DUPS  # Équivalent ZSH de ignoreboth
        HISTSIZE=100000
        HISTFILESIZE=200000

        # Alias complets
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

        # Charger .zshrc si existant
        [ -f ~/.zshrc ] && source ~/.zshrc

        echo -e '\\033[0m'
        echo '✅ Environnement zsh complètement configuré!'
    "
    exit
fi

# Si déjà en zsh
clear
echo -e '\\033[0;32m'
cat << "EOF"
██╗░░░░░░█████╗░░██████╗░░█████╗░
██║░░░░░██╔══██╗██╔════╝░██╔══██╗
██║░░░░░██║░░██║██║░░██╗░██║░░██║
██║░░░░░██║░░██║██║░░╚██╗██║░░██║
███████╗╚█████╔╝╚██████╔╝╚█████╔╝
╚══════╝░╚════╝░░╚═════╝░░╚════╝░
EOF
echo -e '\\033[0m'
