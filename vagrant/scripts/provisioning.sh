#!/bin/bash
set -eo pipefail

# Configuration centralisée
CONFIG=(
  [VM_IP]="127.0.0.1"
  [SSH_PORT]="50210" 
  [SSH_USER]="vagrant"
  [SSH_PASS]="vagrant"
  [SCRIPTS]="base-setup.sh ansible-setup.sh"
  [ANSIBLE_VERSION]="2.15.3"
)

# Fonctions améliorées
ssh_connect() {
  sshpass -p "${CONFIG[SSH_PASS]}" \
    ssh -o StrictHostKeyChecking=no \
    -o ConnectTimeout=10 \
    -p "${CONFIG[SSH_PORT]}" \
    "${CONFIG[SSH_USER]}@${CONFIG[VM_IP]}" "$@"
}

scp_transfer() {
  sshpass -p "${CONFIG[SSH_PASS]}" \
    scp -o StrictHostKeyChecking=no \
    -P "${CONFIG[SSH_PORT]}" \
    "$1" "${CONFIG[SSH_USER]}@${CONFIG[VM_IP]}:$2"
}

check_dependencies() {
  if ! command -v sshpass &> /dev/null; then
    echo "➡ Installation de sshpass..."
    brew install hudochenkov/sshpass/sshpass || {
      echo "❌ Échec installation sshpass"
      exit 1
    }
  fi
}

transfer_scripts() {
  for script in ${CONFIG[SCRIPTS]}; do
    echo "📦 Transfert de ${script}..."
    scp_transfer "scripts/vm-provisioning/${script}" "/tmp/" || {
      echo "⚠ Échec transfert, nouvelle tentative..."
      sleep 2
      scp_transfer "scripts/vm-provisioning/${script}" "/tmp/"
    }
  done
}

execute_scripts() {
  ssh_connect "chmod +x /tmp/*.sh"
  
  for script in ${CONFIG[SCRIPTS]}; do
    echo "🛠 Exécution de ${script}..."
    if [[ "${script}" == "ansible-setup.sh" ]]; then
      ssh_connect "sudo /tmp/${script} --ansible-version ${CONFIG[ANSIBLE_VERSION]}"
    else
      ssh_connect "sudo /tmp/${script}"
    fi
  done
}

# Flux principal
main() {
  echo "🔌 Début du provisionnement via NAT..."
  check_dependencies
  transfer_scripts
  execute_scripts
  echo "✅ Provisionnement terminé avec succès | IP: ${CONFIG[VM_IP]} Port: ${CONFIG[SSH_PORT]}"
}

main "$@"
