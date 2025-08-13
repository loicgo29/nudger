#!/bin/bash
set -eo pipefail

# Configuration centrale
CONFIG=(
  [LAB_DIR]="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  [ANSIBLE_DIR]="${LAB_DIR}/ansible"
  [PLAYBOOK_REPO]="https://github.com/loicgo29/nudger.git"
  [PLAYBOOK_BRANCH]="main"
  [VM_SSH_PORT]="50210"
  [VM_IP]="127.0.0.1"
  [SSH_USER]="vagrant"
  [SSH_PASS]="vagrant"
)

# Couleurs pour le logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Fonctions utilitaires
log() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; exit 1; }

clean_environment() {
  log "Nettoyage de l'environnement..."
  if [ -d "${CONFIG[LAB_DIR]}/.vagrant" ]; then
    (cd "${CONFIG[LAB_DIR]}" && vagrant destroy -f) || warn "Aucune VM à nettoyer"
  fi
  rm -rf "${CONFIG[ANSIBLE_DIR]}/playbooks" 2>/dev/null || true
}

setup_ansible_content() {
  log "Configuration du contenu Ansible..."
  if [ ! -d "${CONFIG[ANSIBLE_DIR]}/playbooks" ]; then
    git clone -b "${CONFIG[PLAYBOOK_BRANCH]}" --depth 1 \
      "${CONFIG[PLAYBOOK_REPO]}" "${CONFIG[ANSIBLE_DIR]}/playbooks" ||
      fail "Échec du clonage du dépôt"
  else
    (cd "${CONFIG[ANSIBLE_DIR]}/playbooks" && git pull) ||
      warn "Problème lors de la mise à jour"
  fi
}

start_vm() {
  log "Démarrage de la VM Vagrant..."
  (cd "${CONFIG[LAB_DIR]}" && vagrant up --provider=qemu) || {
    fail "Échec du démarrage de la VM"
  }
}

remote_provision() {
  local max_retries=3
  local retry_delay=5
  local attempt=0
  local success=false

  while [ $attempt -lt $max_retries ]; do
    ((attempt++))
    log "Tentative de provisionnement $attempt/$max_retries..."
    
    if sshpass -p "${CONFIG[SSH_PASS]}" \
      ssh -o StrictHostKeyChecking=no \
      -o ConnectTimeout=10 \
      -p "${CONFIG[VM_SSH_PORT]}" \
      "${CONFIG[SSH_USER]}@${CONFIG[VM_IP]}" \
      "sudo /vagrant/scripts/remote-provisioning.sh"; then
      success=true
      break
    fi
    
    warn "Échec, nouvelle tentative dans $retry_delay secondes..."
    sleep $retry_delay
  done

  if ! $success; then
    fail "Échec du provisionnement après $max_retries tentatives"
  fi
}

main() {
  [[ "$*" =~ "--clean" ]] && clean_environment

  # Workflow principal
  setup_ansible_content
  start_vm
  remote_provision

  log "Provisionnement terminé avec succès!"
  echo -e "Accès VM: ${YELLOW}ssh -p ${CONFIG[VM_SSH_PORT]} ${CONFIG[SSH_USER]}@${CONFIG[VM_IP]}${NC}"
  echo -e "Mot de passe: ${YELLOW}${CONFIG[SSH_PASS]}${NC}"
}

# Vérification des prérequis
if ! command -v sshpass &> /dev/null; then
  brew install hudochenkov/sshpass/sshpass || fail "Installation de sshpass requise"
fi

main "$@"
