#!/usr/bin/env bash
set -euo pipefail
DIRHOME=/Users/loicgourmelon/devops/nudger
# --- PRÉREQUIS ---
# --- Vérification des prérequis ---
command -v hcloud >/dev/null 2>&1 || { echo "❌ hcloud CLI manquant. Installe-le avant de continuer."; exit 1; }
command -v envsubst >/dev/null 2>&1 || { echo "❌ envsubst manquant (paquet gettext)."; exit 1; }
command -v nc >/dev/null 2>&1 || { echo "❌ nc (netcat) manquant."; exit 1; }
command -v ssh >/dev/null 2>&1 || { echo "❌ ssh manquant."; exit 1; }
command -v ssh-keygen >/dev/null 2>&1 || { echo "❌ ssh-keygen manquant."; exit 1; }

# Vérification du fichier template
[[ -f $DIRHOME/create-VM/vps/cloud-init-template.yaml ]] || { echo "❌ $DIR/cloud-init-template.yaml manquant."; exit 1; }

# Vérification de la clé privée SSH
[[ -f ~/.ssh/id_vm_ed25519 ]] || { echo "❌ Clé privée SSH ~/.ssh/id_vm_ed25519 manquante."; exit 1; }

echo "✅ Tous les prérequis sont présents, le script peut démarrer..."


for cmd in hcloud envsubst nc ssh ssh-keygen scp; do
    command -v $cmd >/dev/null 2>&1 || { echo "❌ $cmd manquant. Installe-le avant de continuer."; exit 1; }
done

echo "✅ Tous les prérequis sont présents"

# --- ARGUMENTS ---
if [[ $# -ne 3 ]]; then
    echo "Usage: $0 <VM_NAME> <USER> <DEPOT_GIT>"
    exit 1
fi

NAME="$1"
USER="$2"
DEPOT_GIT="$3"
ID_SSH="id_vm_ed25519"
BRANCH="main"
ID_SSH_PUB=$(cat ~/.ssh/${ID_SSH}.pub)
REPO_NAME=$(basename "$DEPOT_GIT" .git)

# --- Génération cloud-init ---
echo "➡️ Génération du cloud-init.yaml pour $USER et $DEPOT_GIT"
export USER DEPOT_GIT ID_SSH_PUB
envsubst < $DIRHOME/create-VM/vps/cloud-init-template.yaml > $DIRHOME/create-VM/vps/cloud-init.yaml
echo "✅ cloud-init.yaml généré"

if hcloud server describe "$NAME" >/dev/null 2>&1; then
  echo "Suppression du serveur $NAME existant..."
  hcloud server delete "$NAME"
fi

# --- Création VM Hetzner ---
echo "➡️ Création de la VM $NAME..."
OUTPUT=$(hcloud server create \
  --name "$NAME" \
  --image ubuntu-22.04 \
  --type cpx21 \
  --user-data-from-file $DIRHOME/create-VM/vps/cloud-init.yaml \
  --ssh-key loic-vm-key)
echo "$OUTPUT"

# --- Extraction IP ---
VM_IP=$(echo "$OUTPUT" | awk '/IPv4:/ {print $2}')
[[ -n "$VM_IP" ]] || { echo "❌ Impossible de récupérer l'adresse IP"; exit 1; }
echo "✅ VM IP: $VM_IP"

# --- Nettoyage known_hosts ---
ssh-keygen -R "$VM_IP" >/dev/null 2>&1 || true

# --- Attente SSH ---
echo "⏳ Attente de SSH..."
while ! nc -z -w2 "$VM_IP" 22; do sleep 2; done

# --- Préparation SSH sur VM ---
ssh -o StrictHostKeyChecking=no -i ~/.ssh/$ID_SSH "$USER@$VM_IP" "
mkdir -p ~/.ssh
chmod 700 ~/.ssh
"

scp -o StrictHostKeyChecking=no -i ~/.ssh/$ID_SSH ~/.ssh/$ID_SSH "$USER@$VM_IP:/home/$USER/.ssh/id_deploy"
ssh -o StrictHostKeyChecking=no -i ~/.ssh/$ID_SSH "$USER@$VM_IP" "
chmod 600 ~/.ssh/id_deploy
chown $USER:$USER ~/.ssh/id_deploy
"

# --- Config Git ---
ssh -o StrictHostKeyChecking=no -i ~/.ssh/$ID_SSH "$USER@$VM_IP" "
cat > ~/.ssh/config <<'EOF'
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_deploy
  StrictHostKeyChecking no
EOF
chmod 600 ~/.ssh/config
chown $USER:$USER ~/.ssh/config

ssh-keyscan github.com >> ~/.ssh/known_hosts
chmod 644 ~/.ssh/known_hosts
chown $USER:$USER ~/.ssh/known_hosts

git config --global user.name 'Ton Nom'
git config --global user.email 'ton.email@example.com'
"

# --- Clonage du dépôt ---
ssh -o StrictHostKeyChecking=no -i ~/.ssh/$ID_SSH "$USER@$VM_IP" "
if [ -d ~/$REPO_NAME ]; then rm -rf ~/$REPO_NAME; fi
GIT_SSH_COMMAND='ssh -i ~/.ssh/id_deploy -o StrictHostKeyChecking=no' \
git clone --branch $BRANCH --single-branch $DEPOT_GIT ~/$REPO_NAME
"

echo "✅ Déploiement Git terminé sur $VM_IP"
echo "Tu peux te connecter avec: ssh -i ~/.ssh/$ID_SSH $USER@$VM_IP"

