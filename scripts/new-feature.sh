#!/usr/bin/env bash
set -euo pipefail

# --- Config ---
default_prefix="feat"
today=$(date +"%Y%m%d")
branch_name=""

# --- Variables PR ---
assignee="loicgo29"               # ton pseudo GitHub
reviewers="loicgo29"              # reviewers par défaut
labels="automated,feature"        # labels par défaut
base_branch="main"                # trunk base branch

# --- Check args ---
if [ $# -lt 1 ]; then
  echo "Usage: $0 <nom-fonctionnalite> [prefix]"
  echo "Ex: $0 login feat"
  exit 1
fi

feature=$1
prefix=${2:-$default_prefix}

# --- Force update main ---
echo "🔄 Mise à jour de $base_branch..."
git checkout $base_branch
git pull origin $base_branch

# --- Génération nom de branche ---
branch_name="${prefix}/${today}-${feature}"

# --- Création et push ---
echo "🌱 Création de la branche '$branch_name'..."
git checkout -b "$branch_name"
git push -u origin "$branch_name"

# --- Création PR (via GitHub CLI) ---
if command -v gh >/dev/null 2>&1; then
  echo "🚀 Ouverture de la Pull Request..."
  gh pr create \
    --base "$base_branch" \
    --head "$branch_name" \
    --title "$branch_name" \
    --body "Branche créée automatiquement le $today pour *$feature*" \
    --assignee "$assignee" \
    --label "$labels" \
    --reviewer "$reviewers"
else
  echo "⚠️ GitHub CLI (gh) non installé, pas de PR automatique."
fi

echo "✅ Branche '$branch_name' créée, suivie et PR ouverte (si possible)."

