#!/usr/bin/env bash
set -euo pipefail

# --- Vérification des prérequis ---
command -v hcloud >/dev/null 2>&1 || { echo "❌ hcloud CLI manquant. Installe-le avant de continuer."; exit 1; }
command -v envsubst >/dev/null 2>&1 || { echo "❌ envsubst manquant (paquet gettext)."; exit 1; }
command -v nc >/dev/null 2>&1 || { echo "❌ nc (netcat) manquant."; exit 1; }
command -v ssh >/dev/null 2>&1 || { echo "❌ ssh manquant."; exit 1; }
command -v ssh-keygen >/dev/null 2>&1 || { echo "❌ ssh-keygen manquant."; exit 1; }

# Vérification du fichier template
[[ -f ./cloud-init-template.yaml ]] || { echo "❌ cloud-init-template.yaml manquant."; exit 1; }

# Vérification de la clé privée SSH
[[ -f ~/.ssh/id_vm_ed25519 ]] || { echo "❌ Clé privée SSH ~/.ssh/id_vm_ed25519 manquante."; exit 1; }

echo "✅ Tous les prérequis sont présents, le script peut démarrer..."

# --- Vérification des arguments ---
if [[ $# -ne 4 ]]; then
  echo "Usage: $0 <USER> <DEPOT-GIT> <VM-NAME> <ID-SSH>"
  exit 1
fi

USER=$1
DEPOT_GIT=$2
NAME=$3
ID_SSH=$4   # ex: id_vm_ed25519

# --- Génération du cloud-init.yaml ---
echo "➡️  Génération du cloud-init.yaml pour l'utilisateur '$USER', dépôt '$DEPOT_GIT' et clé '$ID_SSH'"

export USER
export DEPOT_GIT
export ID_SSH_PUB="$(cat ~/.ssh/${ID_SSH}.pub)"

envsubst < cloud-init-template.yaml > cloud-init.yaml

echo "✅ Fichier cloud-init.yaml généré"

# --- Création de la VM ---
echo "➡️  Lancement de la création de la VM Hetzner : $NAME"

OUTPUT=$(hcloud server create \
  --name "$NAME" \
  --image ubuntu-22.04 \
  --type cpx21 \
  --user-data-from-file ./cloud-init.yaml \
  --ssh-key loic-vm-key)

echo "$OUTPUT"   # Log complet pour debug

# --- Extraction de l'IP ---
VM_IP=$(echo "$OUTPUT" | awk '/IPv4:/ {print $2}')

if [[ -z "$VM_IP" ]]; then
  echo "❌ Impossible de récupérer l'adresse IPv4 de la VM"
  exit 1
fi

# --- Supprime l'ancienne entrée SSH si elle existe ---
if grep -q "$VM_IP" ~/.ssh/known_hosts; then
    echo "⚠️  Ancienne clé SSH pour $VM_IP trouvée, suppression..."
    ssh-keygen -R "$VM_IP" > /dev/null 2>&1
fi

echo "✅ Adresse IP de la VM: $VM_IP"
echo "⏳ Vérification que SSH est disponible..."
while ! nc -z -w2 "$VM_IP" 22; do
    echo "SSH non disponible, attente 2s..."
    sleep 2
done

# --- Connexion SSH automatique ---
echo "➡️  Connexion SSH au serveur... "
echo "ssh -i ~/.ssh/$ID_SSH -o StrictHostKeyChecking=no $USER@$VM_IP"
ssh -i ~/.ssh/$ID_SSH -o StrictHostKeyChecking=no "$USER@$VM_IP"

