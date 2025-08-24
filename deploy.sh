#!/usr/bin/env bash
set -euo pipefail

VM_NAME="master1"
USER="ansible"
DEPOT_GIT="https://github.com/loicgo29/nudger.git"
ID_SSH="id_vm_ed25519"

# 1️⃣ Créer la VM
IP=$(./create-VM/vps/create-vm.sh "$VM_NAME" "$USER" "$DEPOT_GIT"  | tee /dev/tty | awk '/VM IP:/ {print $3}')

# 2️⃣ Mettre à jour l’inventaire
cat > inventory.ini <<EOF
[k8s_masters]
$VM_NAME ansible_host=$IP ansible_user=$USER ansible_ssh_private_key_file=$HOME/.ssh/$ID_SSH
EOF

# 3️⃣ Lancer Ansible
cd infra/k8s-ansible
ansible-playbook -i ./inventory.ini ./playbooks/nudger.yml

