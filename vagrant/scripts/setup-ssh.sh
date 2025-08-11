#!/bin/bash
set -euo pipefail

echo "[SETUP-SSH] Configuration des clés SSH et de l'accès"

USER_HOME="/home/vagrant"
SSH_DIR="$USER_HOME/.ssh"
PUB_KEY_PATH="$SSH_DIR/id_rsa.pub"
AUTH_KEYS="$SSH_DIR/authorized_keys"

# Création du dossier .ssh
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
chown vagrant:vagrant "$SSH_DIR"

# Génération de clé si absente
if [ ! -f "$PUB_KEY_PATH" ]; then
    echo "[SETUP-SSH] Génération de la clé SSH..."
    ssh-keygen -t rsa -b 4096 -f "$SSH_DIR/id_rsa" -N "" >/dev/null
    chown vagrant:vagrant "$SSH_DIR/id_rsa" "$PUB_KEY_PATH"
fi

# Ajout de la clé publique à authorized_keys si pas déjà présente
if ! grep -q "$(cat "$PUB_KEY_PATH")" "$AUTH_KEYS" 2>/dev/null; then
    cat "$PUB_KEY_PATH" >> "$AUTH_KEYS"
    chmod 600 "$AUTH_KEYS"
    chown vagrant:vagrant "$AUTH_KEYS"
    echo "[SETUP-SSH] Clé ajoutée à authorized_keys"
fi

# Désactivation du mot de passe pour SSH
sudo sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?ChallengeResponseAuthentication .*/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# Ajout des entrées /etc/hosts si non présentes
if [ -n "${HOSTS_ENTRIES:-}" ]; then
    echo "[SETUP-SSH] Mise à jour de /etc/hosts"
    while read -r entry; do
        grep -qF "$entry" /etc/hosts || echo "$entry" | sudo tee -a /etc/hosts >/dev/null
    done <<< "$HOSTS_ENTRIES"
fi

echo "[SETUP-SSH] Terminé."

