#!/bin/bash

set -e

# Vérifie si l'utilisateur est root
if [[ $EUID -ne 0 ]]; then
   echo "Ce script doit être exécuté en tant que root (sudo)." 
   exit 1
fi

FSTAB="/etc/fstab"
SWAP_LINE=$(grep -E "^[^#].*/swap\.img" $FSTAB || true)

if [[ -z "$SWAP_LINE" ]]; then
    echo "Aucune ligne /swap.img non commentée trouvée dans $FSTAB. Rien à faire."
else
    echo "Commentaire de la ligne /swap.img dans $FSTAB..."
    sed -i.bak '/\/swap\.img/ s/^/#/' $FSTAB
    echo "Sauvegarde originale : $FSTAB.bak"
fi

echo "Redémarrage de kubelet..."
systemctl restart kubelet

echo "Statut kubelet :"
systemctl status kubelet --no-pager
