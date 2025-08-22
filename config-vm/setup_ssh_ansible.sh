#!/bin/bash
set -e

# ================================
# CONFIGURATION SSH POUR ANSIBLE
# ================================

# Variables
ANSIBLE_KEY="$HOME/.ssh/id_ansible"
ANSIBLE_NODES=("49.12.192.213")   # Ajoute ici toutes tes IP de VMs
ANSIBLE_USER="nudgerk8s"

# ----------------------------
# 1️⃣ Génération de la clé SSH pour Ansible
# ----------------------------
if [ ! -f "$ANSIBLE_KEY" ]; then
    echo "🔹 Génération de la clé SSH pour Ansible ($ANSIBLE_KEY)"
    ssh-keygen -t ed25519 -f "$ANSIBLE_KEY" -N ""
else
    echo "🔹 La clé SSH $ANSIBLE_KEY existe déjà, utilisation existante"
fi

# Lancer l'agent SSH et ajouter la clé
eval "$(ssh-agent -s)"
ssh-add "$ANSIBLE_KEY"

# ----------------------------
# 2️⃣ Copier la clé sur toutes les VMs cibles
# ----------------------------
for NODE in "${ANSIBLE_NODES[@]}"; do
    echo "🔹 Copie de la clé sur $NODE"
    ssh-copy-id -i "${ANSIBLE_KEY}.pub" "$ANSIBLE_USER@$NODE"
done

# ----------------------------
# 3️⃣ Instructions finales
# ----------------------------
echo "✅ Clé SSH pour Ansible installée et copiée sur tous les nœuds."
echo "➡️ Mets à jour ton inventory.ini avec :"
echo "ansible_ssh_private_key_file=$ANSIBLE_KEY"

