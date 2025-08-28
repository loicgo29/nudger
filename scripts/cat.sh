#!/usr/bin/env bash
# walkcat.sh — liste tous les fichiers d'un répertoire et les affiche
# Usage: ./walkcat.sh [DIR]
# Options via variables d'env :
#   SKIP_BINARY=1  # (défaut) saute les binaires
#   MAX_BYTES=0    # (défaut) pas de limite; sinon tronque l'affichage

set -euo pipefail

DIR="${1:-.}"
SKIP_BINARY="${SKIP_BINARY:-1}"
MAX_BYTES="${MAX_BYTES:-0}"

if ! command -v find >/dev/null; then
  echo "find est requis"; exit 1
fi

find "$DIR" -type f -print0 | while IFS= read -r -d '' f; do
  echo "===== $f ====="
  if [[ "$SKIP_BINARY" == "1" ]]; then
    # Détecte les binaires proprement
    if command -v file >/dev/null && file --mime "$f" | grep -q 'charset=binary'; then
      echo "(binaire : ignoré)"; echo; continue
    fi
  fi

  if [[ "${MAX_BYTES}" =~ ^[0-9]+$ ]] && (( MAX_BYTES > 0 )); then
    # Affiche au plus MAX_BYTES octets
    head -c "$MAX_BYTES" "$f" || true
    # Indique si tronqué (si wc dispo)
    if command -v wc >/dev/null && [ "$(wc -c <"$f")" -gt "$MAX_BYTES" ]; then
      echo -e "\n…(tronqué à ${MAX_BYTES} octets)"
    fi
  else
    cat "$f" || true
  fi
  echo
done

