#!/bin/bash
set -e

###############################################################
# Installation complète outils DevOps et Ansible
###############################################################

# Désactive les prompts needrestart et redémarrage automatique
export NEEDRESTART_MODE=a

# Modifie la config globale pour redémarrage automatique
CONF_FILE="/etc/needrestart/needrestart.conf"
sudo cp "$CONF_FILE" "${CONF_FILE}.bak" 2>/dev/null || true

if grep -q '^\$nrconf{restart}' "$CONF_FILE" 2>/dev/null; then
    sudo sed -i "s/^\$nrconf{restart}.*/\$nrconf{restart} = 'a';/" "$CONF_FILE"
else
    echo "\$nrconf{restart} = 'a';" | sudo tee -a "$CONF_FILE" > /dev/null
fi

# Désactive vérification du noyau
sudo sed -i 's|^#\$nrconf{kernelhints} = -1;|\$nrconf{kernelhints} = -1;|' "$CONF_FILE"

# Mise à jour non interactive
sudo -E apt update && sudo -E apt upgrade -y

echo "🔹 Installation des dépendances"
sudo apt install -y zsh git curl wget jq tree unzip bash-completion make tar gzip python3-venv

# Virtualenv pour Ansible
ANSIBLE_VENV="$HOME/ansible_venv"

create_ansible_venv() {
    echo "🔹 Création du virtualenv Ansible dans $ANSIBLE_VENV"
    python3 -m venv "$ANSIBLE_VENV"
}

if [ ! -d "$ANSIBLE_VENV" ] || [ ! -f "$ANSIBLE_VENV/bin/activate" ]; then
    echo "⚠️  Virtualenv manquant ou incomplet. Reconstruction..."
    rm -rf "$ANSIBLE_VENV"
    create_ansible_venv
else
    echo "✅ Virtualenv Ansible déjà présent."
fi

source "$ANSIBLE_VENV/bin/activate"
pip install --upgrade pip
pip install "ansible-core>=2.16,<2.18" ansible-lint openshift kubernetes pyyaml

# Collections indispensables
ansible-galaxy collection install kubernetes.core ansible.posix community.general --force

# Collections depuis requirements.yml
REQUIREMENTS_FILE="$HOME/nudger/infra/k8s-ansible/requirements.yml"
if [ -f "$REQUIREMENTS_FILE" ]; then
    echo "🔹 Installation des collections depuis requirements.yml"
    ansible-galaxy collection install -r "$REQUIREMENTS_FILE" --force
fi

echo "🔹 Versions installées :"
ansible --version

# fzf
if [ ! -d "$HOME/.fzf" ]; then
    echo "🔹 Installation de fzf"
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all
fi

# lazygit
if ! command -v lazygit &> /dev/null; then
    echo "🔹 Installation de lazygit"
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" \
        | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin
    rm -rf lazygit.tar.gz lazygit
fi

echo "✅ Installation terminée. Active le venv avec : source ~/ansible_venv/bin/activate"

