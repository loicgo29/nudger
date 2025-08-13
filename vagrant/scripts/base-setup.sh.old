#!/bin/bash
set -euo pipefail

# Configuration
USER="vagrant"
LOG_FILE="/var/log/base-setup.log"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Mise à jour et installation des dépendances de base..."
apt-get update -qq >> "$LOG_FILE" 2>&1
apt-get install -y -qq \
  git \
  curl \
  vim \
  python3-pip \
  python3-venv \
  sshpass \
  net-tools >> "$LOG_FILE" 2>&1

# Configuration SSH minimale
mkdir -p "/home/$USER/.ssh"
chmod 700 "/home/$USER/.ssh"
echo "vagrant:vagrant" | chpasswd
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd

log "✅ Base système configurée"
