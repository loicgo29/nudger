#!/usr/bin/env bash
set -euo pipefail

VM_NAME="master1"
USER="ansible"
DEPOT_GIT="git@github.com:loicgo29/nudger.git"
ID_SSH="id_vm_ed25519"
ANSIBLE_VENV="/home/$USER/ansible_venv"

# --- 1️⃣ Créer la VM et récupérer l'IP ---
IP=$(./create-VM/vps/create-vm.sh "$VM_NAME" "$USER" "$DEPOT_GIT" | tee /dev/tty | awk -F' ' '/VM IP:/ {print $NF}')


# --- 2️⃣ Générer l’inventaire pour bootstrap (Python système) ---
export VM_NAME USER IP ID_SSH ANSIBLE_VENV
envsubst < infra/k8s-ansible/inventory.ini.j2 > infra/k8s-ansible/inventory.ini

echo "✅ Inventory généré avec IP $IP"

# --- 3️⃣ Bootstrap Ansible (installer venv et Ansible) ---
echo "➡️ Bootstrap Ansible sur $VM_NAME..."
cd infra/k8s-ansible
ansible-playbook -i ./inventory.ini ./playbooks/nudger.yml

echo "ssh -i ~/.ssh/id_vm_ed25519 ansible@$IP"
