#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: rename_role_var.sh <role_dir> <var_name> [--apply]

- <role_dir> : chemin du rôle (ex: infra/k8s_ansible/roles/kubernetes/)
- <var_name> : nom de la variable à renommer (ex: docker_packages)
- --apply    : exécute réellement les modifications (par défaut: dry-run)

Ce script :
  1) Renomme la variable en <role>_<var_name>
  2) Déplace le bloc depuis vars/main.yml vers defaults/main.yml
  3) Met à jour toutes les occurrences dans le rôle
EOF
}

if [[ $# -lt 2 ]]; then usage; exit 1; fi

ROLE_DIR="$1"
VAR_NAME="$2"
APPLY=false
if [[ "${3:-}" == "--apply" ]]; then APPLY=true; fi

# Normalise le chemin
ROLE_DIR="${ROLE_DIR%/}/"
ROLE_NAME="$(basename "${ROLE_DIR%/}")"
NEW_VAR="${ROLE_NAME}_${VAR_NAME}"

VARS_FILE="${ROLE_DIR}vars/main.yml"
DEFAULTS_FILE="${ROLE_DIR}defaults/main.yml"

# Vérifs de base
[[ -d "$ROLE_DIR" ]] || { echo "ERR: rôle introuvable: $ROLE_DIR" >&2; exit 1; }
[[ -f "$VARS_FILE" ]] || { echo "WARN: $VARS_FILE introuvable (rien à déplacer). On renomme quand même les occurrences."; }
mkdir -p "$(dirname "$DEFAULTS_FILE")"
[[ -f "$DEFAULTS_FILE" ]] || { $APPLY || true; }

# Fichiers temporaires
TMPDIR="$(mktemp -d)"
EXTRACT="${TMPDIR}/extract.yml"
VARS_NEW="${TMPDIR}/vars.new.yml"
DEFAULTS_NEW="${TMPDIR}/defaults.new.yml"
REPLACE_LIST="${TMPDIR}/replace.list"

cleanup(){ rm -rf "$TMPDIR"; }
trap cleanup EXIT

# 1) Extraire le bloc YAML de VARS_FILE (si présent)
if [[ -f "$VARS_FILE" ]]; then
awk -v VAR="$VAR_NAME" -v EXT="$EXTRACT" -v KEEP="$VARS_NEW" '
  function is_top_delim(line) {
    return match(line, "^[A-Za-z0-9_]+:[[:space:]]*$") \
        || match(line, "^[A-Za-z0-9_]+:[[:space:]].*$") \
        || match(line, "^#") \
        || match(line, "^(---|\\.\\.\\.)[[:space:]]*$")
  }
  BEGIN { state=0 }
  {
    if (state==0) {
      # DÉPART DE BLOC: clé top-level, avec OU sans valeur inline
      if ($0 ~ "^" VAR ":[[:space:]]*($|.+)$") { state=1; print > EXT; next }
      else { print > KEEP; next }
    } else if (state==1) {
      # FIN DE BLOC: dès qu’on voit une autre clé top-level, un commentaire ou ---/...
      if (is_top_delim($0)) { state=0; print > KEEP; next }
      else { print > EXT; next }
    }
  }
' "$VARS_FILE"

  # Si on a extrait quelque chose, renommer la clé au 1er niveau
  if [[ -s "$EXTRACT" ]]; then
    # remplace la 1re ligne "var_name:" par "new_var:"
    awk -v OLD="$VAR_NAME" -v NEW="$NEW_VAR" '
      NR==1 { sub("^"OLD":",""NEW":"); print; next }
      { print }
    ' "$EXTRACT" > "${EXTRACT}.renamed"

    # Préparer defaults.new (concat existant + bloc)
    if [[ -f "$DEFAULTS_FILE" ]]; then
      cp "$DEFAULTS_FILE" "$DEFAULTS_NEW"
    else
      printf -- "---\n" > "$DEFAULTS_NEW"
    fi

    # Vérifie collision
    if grep -Eq "^${NEW_VAR}:[[:space:]]*$" "$DEFAULTS_NEW"; then
      echo "ERR: ${NEW_VAR} existe déjà dans ${DEFAULTS_FILE}. Abandon." >&2
      exit 1
    fi

    printf "\n# Added by rename_role_var.sh (from vars/main.yml)\n" >> "$DEFAULTS_NEW"
    cat "${EXTRACT}.renamed" >> "$DEFAULTS_NEW"
  else
    # Aucun bloc extrait: garder VARS_FILE tel quel
    cp "$VARS_FILE" "$VARS_NEW"
  fi
fi

# 2) Lister les fichiers à modifier (occurrences de VAR_NAME) dans le rôle
#    On exclut .git, .venv éventuels, le dossier .ansible, etc.
mapfile -t FILES < <(grep -RIl --exclude-dir=.git --exclude-dir=.venv --exclude-dir=collections \
  --exclude-dir=.ansible --exclude="*.retry" --null -E "\b${VAR_NAME}\b" "$ROLE_DIR" | xargs -0 -I{} echo {})

# 3) Dry-run: montrer le plan
echo "=== Dry-run plan (APPLY=$APPLY) ==="
echo "- Rôle         : $ROLE_NAME"
echo "- Ancienne var : $VAR_NAME"
echo "- Nouvelle var : $NEW_VAR"
if [[ -f "$VARS_FILE" ]]; then
  if [[ -s "$EXTRACT" ]]; then
    echo "- Déplacer bloc de $VARS_FILE -> $DEFAULTS_FILE"
  else
    echo "- Aucun bloc '$VAR_NAME:' trouvé dans $VARS_FILE (rien à déplacer)"
  fi
else
  echo "- $VARS_FILE absent (skip déplacement)"
fi
echo "- Fichiers avec occurrences à remplacer : ${#FILES[@]}"

# Montrer un diff synthétique si on a des nouveaux contenus
if [[ -f "$VARS_FILE" && -s "$EXTRACT" ]]; then
  echo
  echo "== Diff (vars/main.yml) =="
  diff -u "$VARS_FILE" "$VARS_NEW" || true
  echo
  echo "== Diff (defaults/main.yml) =="
  if [[ -f "$DEFAULTS_FILE" ]]; then
    diff -u "$DEFAULTS_FILE" "$DEFAULTS_NEW" || true
  else
    echo "(defaults/main.yml sera créé avec le bloc suivant)"
    cat "$DEFAULTS_NEW"
  fi
fi

# 4) Appliquer si demandé
if $APPLY; then
  # Ecrire vars/main.yml (si présent)
  if [[ -f "$VARS_FILE" ]]; then
    if [[ -s "$EXTRACT" ]]; then
      mv "$VARS_NEW" "$VARS_FILE"
      mv "$DEFAULTS_NEW" "$DEFAULTS_FILE"
    fi
  fi

  # Remplacements dans les fichiers
# Remplacements dans les fichiers — utiliser Perl pour \b
for f in "${FILES[@]}"; do
  perl -0777 -pe "s/\\b${VAR_NAME}\\b/${NEW_VAR}/g" "$f" > "${TMPDIR}/rep.tmp"
  if ! cmp -s "$f" "${TMPDIR}/rep.tmp"; then
    mv "${TMPDIR}/rep.tmp" "$f"
    echo "PATCH: $f"
  else
    rm -f "${TMPDIR}/rep.tmp"
  fi
done

  echo "✅ Terminé (apply)."
else
  echo
  echo "ℹ️  Dry-run uniquement. Ajoute --apply pour écrire les changements."
fi

