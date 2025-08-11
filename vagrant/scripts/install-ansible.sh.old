#!/bin/bash
set -euo pipefail

echo "[ANSIBLE-INSTALL] Installation d'Ansible et dépendances"

# Mise à jour du système
sudo apt-get update -qq
sudo apt-get upgrade -yq

# Paquets de base
sudo DEBIAN_FRONTEND=noninteractive apt-get install -yq \
    unzip iftop curl software-properties-common git vim tree net-tools telnet \
    python3-pip python3-venv sshpass libssl-dev libffi-dev

# Création d'un environnement Python dédié pour Ansible si absent
if [ ! -d "/opt/ansible_venv" ]; then
    echo "[ANSIBLE-INSTALL] Création de l'environnement virtuel..."
    sudo python3 -m venv /opt/ansible_venv
    sudo /opt/ansible_venv/bin/pip install --upgrade pip wheel
fi

# Installation d'Ansible + outils dans le venv
sudo /opt/ansible_venv/bin/pip install \
    ansible-core==2.15.3 \
    ansible-lint==6.22.1 \
    molecule==5.1.0 \
    passlib

# Configuration globale d'Ansible
sudo mkdir -p /etc/ansible
echo -e "[defaults]\ninterpreter_python = /opt/ansible_venv/bin/python3\nhost_key_checking = False" \
    | sudo tee /etc/ansible/ansible.cfg >/dev/null

# Liens symboliques pour accès direct à ansible depuis le PATH
sudo ln -sf /opt/ansible_venv/bin/ansible* /usr/local/bin/

# Installation de collections Ansible utiles
sudo /opt/ansible_venv/bin/ansible-galaxy collection install \
    community.general ansible.posix --force

echo "[ANSIBLE-INSTALL] Terminé."

