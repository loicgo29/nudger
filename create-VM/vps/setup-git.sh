#!/usr/bin/env bash
set -euo pipefail

USER="nudger-k8s"
DEPLOY_KEY="$HOME/.ssh/id_vm_ed25519"
VM_IP="$1"
REPO="git@github.com:loicgo29/nudger.git"
BRANCH="feat/220825"
REPO_NAME=$(basename "$REPO" .git)

# --- Préparer .ssh ---
ssh -o StrictHostKeyChecking=no -i "$DEPLOY_KEY" "$USER@$VM_IP" "mkdir -p ~/.ssh && chmod 700 ~/.ssh"
scp -o StrictHostKeyChecking=no -i "$DEPLOY_KEY" "$DEPLOY_KEY" "$USER@$VM_IP:/home/$USER/.ssh/id_deploy"
ssh -o StrictHostKeyChecking=no -i "$DEPLOY_KEY" "$USER@$VM_IP" "chmod 600 ~/.ssh/id_deploy && chown $USER:$USER ~/.ssh/id_deploy"

# --- Configurer GitHub dans SSH config ---
ssh -o StrictHostKeyChecking=no -i "$DEPLOY_KEY" "$USER@$VM_IP" "
  cat > ~/.ssh/config <<'EOF'
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_deploy
  StrictHostKeyChecking no
EOF
  chmod 600 ~/.ssh/config
  chown $USER:$USER ~/.ssh/config
"

# --- Ajouter github.com dans known_hosts ---
ssh -o StrictHostKeyChecking=no -i "$DEPLOY_KEY" "$USER@$VM_IP" "ssh-keyscan github.com >> ~/.ssh/known_hosts && chmod 644 ~/.ssh/known_hosts && chown $USER:$USER ~/.ssh/known_hosts"

# --- Configurer Git globalement ---
ssh -o StrictHostKeyChecking=no -i "$DEPLOY_KEY" "$USER@$VM_IP" "
  git config --global user.name 'Ton Nom'
  git config --global user.email 'ton.email@example.com'
"

# --- Cloner ou remplacer le repo ---
ssh -o StrictHostKeyChecking=no -i "$DEPLOY_KEY" "$USER@$VM_IP" "
  if [ -d ~/$REPO_NAME ]; then
    echo '⚠️  Répertoire $REPO_NAME existant, suppression pour éviter erreurs'
    rm -rf ~/$REPO_NAME
  fi
  echo '📥 Clonage $REPO_NAME'
  GIT_SSH_COMMAND='ssh -i ~/.ssh/id_deploy -o StrictHostKeyChecking=no' git clone --branch $BRANCH --single-branch $REPO ~/$REPO_NAME

"

echo "✅ Déploiement Git terminé sur $VM_IP"
echo "Tu peux maintenant te connecter et faire git push normalement, la clé est prise en compte."

