#!/bin/bash
set -eo pipefail

# Configuration
LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANSIBLE_DIR="${LAB_DIR}/ansible"
PLAYBOOK_REPO="https://github.com/loicgo29/nudger.git"
PLAYBOOK_BRANCH="main"

# Fonction de nettoyage
clean_environment() {
  echo "🧹 Nettoyage de l'environnement..."
  ./stopvagrant.sh
}

# Installation des dépendances
install_dependencies() {
  echo "📦 Installation des dépendances..."
  if ! command -v vagrant >/dev/null; then
    echo "➡️ Veuillez installer Vagrant manuellement : https://www.vagrantup.com/downloads"
    exit 1
  fi
  
  # Vérification QEMU
  if ! command -v qemu-system-x86_64 >/dev/null; then
    brew install qemu
  fi
}

# Récupération des playbooks
setup_ansible_content() {
  echo "📥 Configuration Ansible..."
  if [ ! -d "${ANSIBLE_DIR}/playbooks" ]; then
    git clone --branch "${PLAYBOOK_BRANCH}" --depth 1 \
      "${PLAYBOOK_REPO}" "${ANSIBLE_DIR}/playbooks"
  else
    git -C "${ANSIBLE_DIR}/playbooks" pull origin "${PLAYBOOK_BRANCH}"
  fi
}

# Exécution principale
main() {
  [[ "$*" =~ "--clean" ]] && clean_environment
  
  install_dependencies
  setup_ansible_content
  
  echo "🚀 Démarrage des VMs..."
  vagrant up --provider=qemu
  
  echo "🛠 Exécution des playbooks Ansible..."
  cd "${ANSIBLE_DIR}"
  ANSIBLE_CONFIG="${ANSIBLE_DIR}/ansible.cfg" \
    ansible-playbook -i inventory.ini playbooks/setup-kubernetes.yml
}

main "$@"
