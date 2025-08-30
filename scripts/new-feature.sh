#!/usr/bin/env bash
set -euo pipefail

# Usage: ./new-feature.sh <feature_name> <type>
# ex: ./new-feature.sh xwiki feat

feature="$1"
type="$2"
today=$(date +%Y%m%d)
branch_name="${type}/${today}-${feature}"
base_branch="main"

# Met à jour la branche principale
echo "🔄 Mise à jour de $base_branch..."
git checkout "$base_branch"
git pull origin "$base_branch"

# Création de la nouvelle branche
echo "🌱 Création de la branche '$branch_name'..."
git checkout -b "$branch_name"

# Si aucun commit, faire un commit initial vide
if [ -z "$(git diff --staged --name-only)" ] && [ -z "$(git diff --name-only)" ]; then
    echo "⚠️ Aucun changement détecté, création d'un commit vide..."
    git commit --allow-empty -m "Initial commit for $branch_name"
fi

# Push de la branche
git push -u origin "$branch_name"

# Création de la PR uniquement s'il y a au moins un commit
if [ -n "$(git rev-list "$base_branch"..HEAD)" ]; then
    echo "🚀 Création de la Pull Request..."
    gh pr create \
        --base "$base_branch" \
        --head "$branch_name" \
        --title "$branch_name" \
        --body "Branche créée automatiquement le $today pour *$feature*"
else
    echo "⚠️ Pas de commit sur la branche, PR non créée."
fi

echo "✅ Branche '$branch_name' prête et suivie sur origin/$branch_name"
