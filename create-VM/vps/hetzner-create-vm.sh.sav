#!/usr/bin/env bash
NAME=$1

echo "➡️  Création de la VM: $NAME"

set -x   # Active le mode debug
hcloud server create \
  --name "$NAME" \
  --image ubuntu-22.04 \
  --type cpx21 \
  --user-data-from-file ./cloud-init.yaml \
  --ssh-key loic-vm-key



