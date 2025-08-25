#!/usr/bin/env bash
set -euo pipefail

# --- Paramètres ---
feature=${1:-feature}         # nom de la fonctionnalité
prefix=${2:-feat}             # préfixe de la branche
assignee=${3:-}               # GitHub username
reviewers=${4:-}              # GitHub reviewers
labels=${5:-}                 # labels séparés par des virgules
today=$(date +%Y%m%d)
branch_name="${prefix}/${today}-${feature}"
base_branch="main"

# --- Mise à jour de main ---
echo "🔄 Mise à jour de $base_branch..."
git checkout "$base_branch"
git pull --ff-only

# --- Création de la branche ---
echo "🌱 Création de la branche '$branch_name'..."
git checkout -b "$branch_name"

# --- Pousser la branche et configurer le suivi ---
git push -u origin "$branch_name"

# --- Vérification des labels existants sur GitHub ---
valid_labels=""
if [ -n "$labels" ]; then
    IFS=',' read -ra all_labels <<< "$labels"
    for l in "${all_labels[@]}"; do
        if gh label list | grep -qx "$l"; then
            valid_labels+="$l,"
        else
            echo "⚠️ Label '$l' n'existe pas, il sera ignoré."
        fi
    done
    valid_labels=${valid_labels%,} # retire la dernière virgule
fi

# --- Création de la PR ---
echo "🚀 Création de la Pull Request..."
cmd=(gh pr create --base "$base_branch" --head "$branch_name" --title "$branch_name" --body "Branche créée automatiquement le $today pour *$feature*" )
[ -n "$assignee" ] && cmd+=(--assignee "$assignee")
[ -n "$reviewers" ] && cmd+=(--reviewer "$reviewers")
[ -n "$valid_labels" ] && cmd+=(--label "$valid_labels")

"${cmd[@]}"

echo "✅ Branche '$branch_name' créée et PR ouverte."

