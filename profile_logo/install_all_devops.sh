#!/bin/bash
###############################################################
#  TITRE: Installation complète outils DevOps et Ansible
#  AUTEUR: Loic G.
#  DESCRIPTION: 
#    - Installe Git, curl, wget, jq, tree, unzip, bash-completion, make, tar, gzip
#    - Crée un virtualenv Python pour Ansible
#    - Installe ansible-core >=2.16 et ansible-lint
#    - Installe fzf et lazygit
###############################################################

set -e

echo "🔹 Mise à jour du système et installation des dépendances"
sudo apt update && sudo apt install -y \
    git curl wget jq tree unzip bash-completion make tar gzip python3-venv

# Crée le virtualenv Ansible si nécessaire
ANSIBLE_VENV="$HOME/ansible_venv"
if [ ! -d "$ANSIBLE_VENV" ]; then
    echo "🔹 Création du virtualenv Ansible dans $ANSIBLE_VENV"
    python3 -m venv "$ANSIBLE_VENV"
fi

# Active le virtualenv
source "$ANSIBLE_VENV/bin/activate"

# Met à jour pip et installe Ansible
echo "🔹 Installation d'Ansible dans le venv"
pip install --upgrade pip
pip install "ansible-core>=2.16,<2.20" ansible-lint

# Vérifie la version
echo "🔹 Versions installées :"
ansible --version

# Installation fzf
if [ ! -d "$HOME/.fzf" ]; then
    echo "🔹 Installation de fzf"
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all
fi

# Installation lazygit
if ! command -v lazygit &> /dev/null; then
    echo "🔹 Installation de lazygit"
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin
    rm -rf lazygit.tar.gz lazygit
fi

echo "✅ Installation terminée. Active le venv avec : source ~/ansible_venv/bin/activate"

