#!/bin/bash
set -e

### Variables ###
PLAYBOOK_REPO="https://github.com/monuser/mon-playbook.git" # <-- à modifier
PLAYBOOK_DIR="$HOME/k8s-ansible"
PLAYBOOK_BRANCH="main"  # ou un tag: v1.2.0

if [[ "$1" == "--clean" ]]; then
  vagrant destroy -f
fi

echo "🚀 [1/5] Mise à jour des paquets..."
brew update

echo "📦 [2/5] Installation dépendances..."
brew install git ansible vagrant virtualbox

echo "📥 [3/5] Récupération du playbook..."
if [ ! -d "$PLAYBOOK_DIR" ]; then
    git clone --branch "$PLAYBOOK_BRANCH" --depth 1 "$PLAYBOOK_REPO" "$PLAYBOOK_DIR"
else
    echo "🔄 Playbook déjà présent, mise à jour..."
    git -C "$PLAYBOOK_DIR" fetch origin
    git -C "$PLAYBOOK_DIR" reset --hard "origin/$PLAYBOOK_BRANCH"
fi

echo "💻 [4/5] Démarrage des VM Vagrant..."
vagrant up --provision

echo "🛠 [5/5] Lancement du playbook Kubernetes..."
cd "$PLAYBOOK_DIR"
ansible-playbook -i inventory.ini setup.yml

echo "✅ Lab Kubernetes prêt à l’emploi !"

