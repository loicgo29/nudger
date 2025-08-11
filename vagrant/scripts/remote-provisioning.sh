#!/bin/bash
set -eo pipefail

VM_IP="127.0.0.1"
SSH_PORT="50210"
SSH_USER="vagrant"
SSH_PASS="vagrant"

echo "🔌 Connexion à la VM via NAT..."

# Installation des dépendances SSH si besoin
if ! command -v sshpass &> /dev/null; then
  brew install hudochenkov/sshpass/sshpass
fi

# Fonction pour exécuter des commandes à distance
run_remote() {
  sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -p "$SSH_PORT" "${SSH_USER}@${VM_IP}" "$@"
}

# Fonction pour copier des fichiers
copy_to_remote() {
  sshpass -p "$SSH_PASS" scp -o StrictHostKeyChecking=no -P "$SSH_PORT" "$1" "${SSH_USER}@${VM_IP}:$2"
}

echo "🛠 Exécution des scripts à distance..."

# 1. Copie des scripts
copy_to_remote "scripts/vm-provisioning/base-setup.sh" "/tmp/"
copy_to_remote "scripts/vm-provisioning/ansible-setup.sh" "/tmp/"

# 2. Exécution séquentielle
run_remote "chmod +x /tmp/*.sh"
run_remote "sudo /tmp/base-setup.sh"
run_remote "sudo /tmp/ansible-setup.sh --ansible-version 2.15.3"

echo "✅ Provisionnement terminé via connexion NAT"
