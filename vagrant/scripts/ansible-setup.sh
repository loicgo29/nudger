#!/bin/bash
set -euo pipefail

# Configuration
ANSIBLE_VERSION="${1:-2.15.3}"
PYTHON_VENV="/opt/ansible_venv"
LOG_FILE="/var/log/ansible-setup.log"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Installation des dépendances spécifiques Ansible..."
apt-get install -y -qq \
  python3-dev \
  libssl-dev \
  libffi-dev >> "$LOG_FILE" 2>&1

log "Création de l'environnement virtuel..."
python3 -m venv "$PYTHON_VENV" >> "$LOG_FILE" 2>&1
"$PYTHON_VENV/bin/pip" install --upgrade pip wheel >> "$LOG_FILE" 2>&1

log "Installation d'Ansible $ANSIBLE_VERSION..."
"$PYTHON_VENV/bin/pip" install \
  "ansible-core==$ANSIBLE_VERSION" \
  ansible-lint \
  kubernetes.core >> "$LOG_FILE" 2>&1

# Configuration globale
cat > /etc/ansible/ansible.cfg <<EOF
[defaults]
interpreter_python = $PYTHON_VENV/bin/python3
host_key_checking = False
EOF

log "✅ Installation Ansible terminée"
