#!/bin/bash

# Étape 1 - Nettoyage complet
sudo apt update
sudo apt install -y zsh
sudo chsh -s $(which zsh) $USER

# Étape 2 - Destruction forcée de bash
cat << 'EOF' > ~/.bashrc
# FORCE ZSH LOAD
if [ -t 1 ]; then
    exec zsh
fi
EOF

# Étape 3 - Exécution IMMÉDIATE
exec zsh -l -i <<'EOZSH'
    # Votre configuration ZSH complète
    clear
    echo -e "\033[0;32m"
    cat << "END"
██╗░░░░░░█████╗░░██████╗░░█████╗░
██║░░░░░██╔══██╗██╔════╝░██╔══██╗
██║░░░░░██║░░██║██║░░██╗░██║░░██║
██║░░░░░██║░░██║██║░░╚██╗██║░░██║
███████╗╚█████╔╝╚██████╔╝╚█████╔╝
╚══════╝░╚════╝░░╚═════╝░░╚════╝░
END

    export KUBECONFIG=~/.k0s/kubeconfig
    source ~/.zshrc 2>/dev/null || true
    
    echo -e "\033[0m"
    echo "🔥 Shell actuel CONFIRMÉ : $(ps -p $$ -o comm=)"
    echo "🔥 Shell configuré : $(grep ^$USER /etc/passwd | cut -d: -f7)"
EOZSH
