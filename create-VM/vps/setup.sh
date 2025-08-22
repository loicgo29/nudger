#!/usr/bin/env bash
set -e

USER="nudger-k8s"
GITHUB_USER="loicgo29"
DEPOT_GIT="nudger"
SSH_KEY="/home/$USER/.ssh/id_vm_ed25519"

# Vérifie si le dépôt existe déjà
if [ ! -d "/home/$USER/$DEPOT_GIT" ]; then
    sudo -u $USER git clone git@github.com:$GITHUB_USER/$DEPOT_GIT.git /home/$USER/$DEPOT_GIT
fi

