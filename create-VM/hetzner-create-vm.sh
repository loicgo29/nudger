#!/usr/bin/env bash
#hcloud ssh-key create --name loic-vm-key --public-key "$(cat ~/.ssh/id_vm_ed25519.pub)"

set -euo pipefail

PREFIX="nudger-vm-k8s"


LAST_NUM=$(hcloud server list -o columns=name \
  | grep -E "^${PREFIX}-[0-9]+" \
  | sed -E "s/^${PREFIX}-//" \
  | sort -n \
  | tail -1 || echo 0)   # <-- si rien, retourne 0


if [[ -z "$LAST_NUM" ]]; then
  LAST_NUM=0
fi

NEXT_NUM=$((LAST_NUM + 1))
NAME="${PREFIX}-${NEXT_NUM}"

echo "➡️  Création de la VM: $NAME"

set -x   # Active le mode debug
hcloud server create \
  --name "$NAME" \
  --image ubuntu-22.04 \
  --type cpx21 \
  --user-data-from-file ./cloud-init.yaml \
  --ssh-key loic-vm-key



