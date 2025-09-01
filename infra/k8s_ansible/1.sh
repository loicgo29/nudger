#!/usr/bin/env bash
set -euo pipefail

dir="${1:?Usage: $0 <directory>}"

# Vérifie que c'est bien un répertoire
if [ ! -d "$dir" ]; then
  echo "❌ $dir n'est pas un dossier"
  exit 1
fi

echo "🔍 Parcours de $dir pour patcher les import_tasks..."

# Cherche tous les fichiers YAML
find "$dir" -type f \( -name '*.yml' -o -name '*.yaml' \) | while read -r file; do
  if grep -qE '^[[:space:]]*- *ansible\.builtin\.import_tasks:' "$file"; then
    echo "⚡ Patch $file"
    # Ajoute un `- name: Import <fichier>` avant chaque import_tasks
    sed -i.bak -E \
      's|^([[:space:]]*)- *ansible\.builtin\.import_tasks: *([^[:space:]].*)$|\1- name: Import \2\
\1  ansible.builtin.import_tasks: \2|' "$file"
  fi
done

echo "✅ Terminé. (des backups .bak ont été créés à côté de chaque fichier modifié)"
