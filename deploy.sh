#!/usr/bin/env bash
set -euo pipefail

# Absolutiser les chemins relativement à ce script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

VM_NAME="master1"
USER="ansible"
DEPOT_GIT="git@github.com:loicgo29/nudger.git"
ID_SSH="id_vm_ed25519"
ANSIBLE_VENV="/home/$USER/ansible_venv"

# --- 1️⃣ Créer la VM et récupérer l'IP ---
IP=$("$SCRIPT_DIR/create-VM/vps/create-vm.sh" "$VM_NAME" "$USER" "$DEPOT_GIT" \
  | tee /dev/tty \
  | awk -F' ' '/VM IP:/ {print $NF}')

# --- 2️⃣ Générer l’inventaire ---
export VM_NAME USER IP ID_SSH ANSIBLE_VENV
envsubst < "$SCRIPT_DIR/infra/k8s-ansible/inventory.ini.j2" \
  > "$SCRIPT_DIR/infra/k8s-ansible/inventory.ini"

echo "✅ Inventory généré avec IP $IP"

# --- 3️⃣ Bootstrap Ansible ---
echo "➡️ Bootstrap Ansible sur $VM_NAME..."
cd "$SCRIPT_DIR/infra/k8s-ansible"
#ansible-playbook -i ./inventory.ini ./playbooks/nudger.yml

echo "ssh -i ~/.ssh/id_vm_ed25519 dev-loic@$IP"

