#!/bin/bash
# setup-git.sh
# Usage: ./setup-git.sh <user> <repo_url> <branch> <git_user_name> <git_user_email>

USER="$1"
REPO="$2"
BRANCH="${3:-main}"
GIT_NAME="$4"
GIT_EMAIL="$5"

if [ -z "$USER" ] || [ -z "$REPO" ] || [ -z "$GIT_NAME" ] || [ -z "$GIT_EMAIL" ]; then
  echo "Usage: $0 <user> <repo_url> <branch> <git_user_name> <git_user_email>"
  exit 1
fi

HOME_DIR="/home/$USER"
TARGET_DIR="$HOME_DIR/nudger"

# --- Configurer Git ---
echo "➡️ Configuration Git pour l'utilisateur $USER..."
sudo -u "$USER" git config --global user.name "$GIT_NAME"
sudo -u "$USER" git config --global user.email "$GIT_EMAIL"

# --- Cloner ou mettre à jour le repo ---
if [ -d "$TARGET_DIR/.git" ]; then
  echo "➡️ Repo déjà existant, mise à jour avec git pull..."
  sudo -u "$USER" git -C "$TARGET_DIR" fetch origin "$BRANCH"
  sudo -u "$USER" git -C "$TARGET_DIR" checkout "$BRANCH"
  sudo -u "$USER" git -C "$TARGET_DIR" pull
else
  echo "➡️ Clonage du repo $REPO sur la branche $BRANCH..."
  sudo -u "$USER" git clone --branch "$BRANCH" --single-branch "$REPO" "$TARGET_DIR" 2>&1 | tee "$HOME_DIR/nudger-git-clone.log"
fi

echo "✅ Setup Git terminé."

