#!/usr/bin/env bash
set -euo pipefail

# Vérifie que le repo est propre (pas de conflits ou fichiers non suivis ignorés)
if ! git diff --quiet || ! git diff --cached --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
  echo "⚠️ Le repo n'est pas clean :"
  git status -s
fi

# Demande un message de commit
if [ $# -eq 0 ]; then
  echo "❌ Tu dois fournir un message de commit"
  exit 1
fi

msg="$*"

# Add + commit + push
git add -A
git commit -m "$msg"
git push

