#!/bin/bash
# ==============================================
# SCRIPT D'INSTALLATION ENVIRONNEMENT DEVOPS
# Auteur : Loic G.
# ==============================================

set -euo pipefail

# Configuration
LOG_DIR="$HOME/log"
mkdir -p "$LOG_DIR"                      # Crée le dossier si nécessaire
LOG_FILE="$LOG_DIR/devops_setup.log"     # Fichier log utilisateur

ANSIBLE_VERSION="${1:-2.15.3}"
PYTHON_VENV="/opt/ansible_venv"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Mise à jour des paquets et installation des dépendances de base..."
apt-get update -qq >> "$LOG_FILE" 2>&1
apt-get install -y -qq python3-dev libssl-dev libffi-dev python3-venv python3-pip >> "$LOG_FILE" 2>&1

# Création du virtualenv si nécessaire
if [ ! -d "$PYTHON_VENV" ]; then
    log "Création de l'environnement virtuel dans $PYTHON_VENV..."
    sudo python3 -m venv "$PYTHON_VENV" >> "$LOG_FILE" 2>&1
else
    log "Le virtualenv $PYTHON_VENV existe déjà, passage à l'installation d'Ansible..."
fi

# Mise à jour de pip et installation d'Ansible
log "Mise à jour de pip et installation de wheel..."
sudo "$PYTHON_VENV/bin/pip" install --upgrade pip wheel >> "$LOG_FILE" 2>&1

log "Installation d'Ansible $ANSIBLE_VERSION et des dépendances..."
sudo "$PYTHON_VENV/bin/pip" install \
  "ansible-core==$ANSIBLE_VERSION" \
  ansible-lint \
  kubernetes.core >> "$LOG_FILE" 2>&1

# Configuration globale Ansible
log "Configuration globale d'Ansible..."
sudo mkdir -p /etc/ansible
sudo tee /etc/ansible/ansible.cfg > /dev/null <<EOF
[defaults]
interpreter_python = $PYTHON_VENV/bin/python3
host_key_checking = False
EOF

# Ajout du venv au PATH utilisateur si nécessaire
if ! grep -q "/opt/ansible_venv/bin" ~/.bashrc; then
  echo 'export PATH="/opt/ansible_venv/bin:$PATH"' >> ~/.bashrc
  log "Ajout de /opt/ansible_venv/bin au PATH dans ~/.bashrc"
fi

# Activation du nouveau PATH dans la session en cours
export PATH="/opt/ansible_venv/bin:$PATH"

log "✅ Installation Ansible terminée"

