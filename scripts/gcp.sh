#!/usr/bin/env bash
set -euo pipefail

# Récupère la branche courante
branch=$(git rev-parse --abbrev-ref HEAD)

# Interdit commit direct sur main/master
if [[ "$branch" == "main" || "$branch" == "master" ]]; then
  echo "❌ Tu es sur '$branch'. Crée une feature branch avant de commit."
  exit 1
fi

# Vérifie l'état du repo
if ! git diff --quiet || ! git diff --cached --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
  echo "📌 Modifs détectées dans le repo :"
  git status -s
else
  echo "✅ Rien à commit, repo clean"
  exit 0
fi

# Vérifie le message de commit
if [ $# -eq 0 ]; then
  echo "❌ Fournis un message de commit"
  exit 1
fi

msg="$*"

# Ajoute, commit et push
echo "➡️ Commit sur la branche '$branch' avec message : \"$msg\""
git add -A
git commit -m "$msg"
git push -u origin "$branch"

