#!/usr/bin/env bash
set -euo pipefail

# Vérification prérequis
for cmd in hcloud envsubst nc ssh ssh-keygen; do
    command -v $cmd >/dev/null 2>&1 || { echo "❌ $cmd manquant"; exit 1; }
done
[[ -f ./cloud-init-template.yaml ]] || { echo "❌ cloud-init-template.yaml manquant"; exit 1; }
[[ -f ~/.ssh/id_ansible ]] || { echo "❌ Clé privée SSH ~/.ssh/id_ansible manquante"; exit 1; }

# Vérification des arguments
if [[ $# -ne 3 ]]; then
    echo "Usage: $0 <VM-NAME> <IMAGE-TYPE> <SSH-PUB-FILE>"
    exit 1
fi

VM_NAME=$1
IMAGE_TYPE=$2
SSH_PUB_FILE=$3
export ID_ANSIBLE_PUB="$(cat $SSH_PUB_FILE)"

# Génération du cloud-init.yaml
envsubst < cloud-init-template.yaml > cloud-init.yaml
echo "✅ cloud-init.yaml généré"

# Création VM Hetzner
OUTPUT=$(hcloud server create \
    --name "$VM_NAME" \
    --image "$IMAGE_TYPE" \
    --type cpx21 \
    --user-data-from-file ./cloud-init.yaml \
    --ssh-key loic-vm-key)
echo "$OUTPUT"

# Récupération IP
VM_IP=$(echo "$OUTPUT" | awk '/IPv4:/ {print $2}')
[[ -z "$VM_IP" ]] && { echo "❌ Impossible de récupérer l'IP"; exit 1; }

# Suppression ancienne clé SSH
ssh-keygen -R "$VM_IP" >/dev/null 2>&1

# Attente SSH
echo "⏳ Attente que SSH soit disponible..."
until nc -z -w2 "$VM_IP" 22; do sleep 2; done

echo "✅ SSH prêt sur $VM_IP"
echo "➡️ Connexion test : ssh -i ~/.ssh/id_ansible ansible@$VM_IP"

# Déploiement Git
./setup-git.sh "$VM_IP"
