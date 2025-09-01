#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: prefix_role_var.sh <role_dir> <var_name> [--apply]

- <role_dir> : chemin du rôle (ex: infra/k8s_ansible/roles/kubernetes/)
- <var_name> : nom de la variable à préfixer (ex: disable_swap_comment_fstab)
- --apply    : applique les changements (par défaut: dry-run)

Ce script :
  1) Renomme la clé top-level <var_name> -> <role>_<var_name> dans defaults/main.yml et/ou vars/main.yml si elle existe
  2) Remplace toutes les occurrences de la variable dans le rôle (tasks, handlers, templates, meta, defaults, vars)
  3) Montre les diffs en dry-run avant d'écrire quoi que ce soit
EOF
}

if [[ $# -lt 2 ]]; then usage; exit 1; fi

ROLE_DIR="${1%/}/"
VAR_NAME="$2"
APPLY=false
if [[ "${3:-}" == "--apply" ]]; then APPLY=true; fi

[[ -d "$ROLE_DIR" ]] || { echo "ERR: rôle introuvable: $ROLE_DIR" >&2; exit 1; }
ROLE_NAME="$(basename "${ROLE_DIR%/}")"
NEW_VAR="${ROLE_NAME}_${VAR_NAME}"

DEFAULTS_FILE="${ROLE_DIR}defaults/main.yml"
VARS_FILE="${ROLE_DIR}vars/main.yml"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

# --- helpers awk pour renommer un bloc top-level (clé avec ou sans valeur inline)
rename_key_in_file() {
  local src="$1" old="$2" new="$3" out="$4"
  awk -v OLD="$old" -v NEW="$new" '
    function is_top_delim(line) {
      return match(line, "^[A-Za-z0-9_]+:[[:space:]]*$") \
          || match(line, "^[A-Za-z0-9_]+:[[:space:]].*$") \
          || match(line, "^(---|\\.\\.\\.)[[:space:]]*$") \
          || match(line, "^#")
    }
    BEGIN { state=0 }
    {
      if (state==0) {
        if ($0 ~ "^" OLD ":[[:space:]]*($|.+)$") {
          state=1
          sub("^" OLD ":", NEW ":")
          print
          next
        } else {
          print
          next
        }
      } else if (state==1) {
        if (is_top_delim($0)) { state=0; print; next }
        else { print; next }
      }
    }
  ' "$src" > "$out"
}

# Prépare diffs
DIFFS=()
FILES_TO_PATCH=()

process_yaml_file() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  if grep -Eq "^${VAR_NAME}:[[:space:]]*($|.+)$" "$file"; then
    local out="$TMPDIR/$(basename "$file").new"
    rename_key_in_file "$file" "$VAR_NAME" "$NEW_VAR" "$out"
    DIFFS+=("diff -u $file $out")
  fi
}

process_yaml_file "$DEFAULTS_FILE"
process_yaml_file "$VARS_FILE"

# Lister les fichiers du rôle où remplacer les occurrences (vrais word boundaries via Perl)
# On exclut quelques répertoires parasites
mapfile -t FILES_TO_PATCH < <(
  grep -RIl --exclude-dir=.git --exclude-dir=.venv --exclude-dir=.ansible --exclude-dir=collections \
      --exclude="*.retry" --null -E "\b${VAR_NAME}\b" "$ROLE_DIR" \
  | xargs -0 -I{} echo {}
)

echo "=== Dry-run plan (APPLY=$APPLY) ==="
echo "- Rôle         : $ROLE_NAME"
echo "- Ancienne var : $VAR_NAME"
echo "- Nouvelle var : $NEW_VAR"
echo "- Fichiers YAML à renommer (clé top-level si présente) :"
[[ -f "$DEFAULTS_FILE" ]] && echo "  - ${DEFAULTS_FILE}"
[[ -f "$VARS_FILE" ]] && echo "  - ${VARS_FILE}"
echo "- Fichiers avec occurrences à remplacer : ${#FILES_TO_PATCH[@]}"

# Montrer diffs YAML
for d in "${DIFFS[@]}"; do
  echo
  echo "== ${d#diff -u } =="
  eval "$d" || true
done

if $APPLY; then
  # Applique renommage dans defaults/vars si modifiés
  if [[ -f "$DEFAULTS_FILE" ]] && grep -q "^${VAR_NAME}:" "$DEFAULTS_FILE"; then
    rename_key_in_file "$DEFAULTS_FILE" "$VAR_NAME" "$NEW_VAR" "$TMPDIR/defaults.new"
    mv "$TMPDIR/defaults.new" "$DEFAULTS_FILE"
    echo "PATCH: $DEFAULTS_FILE"
  fi
  if [[ -f "$VARS_FILE" ]] && grep -q "^${VAR_NAME}:" "$VARS_FILE"; then
    rename_key_in_file "$VARS_FILE" "$VAR_NAME" "$NEW_VAR" "$TMPDIR/vars.new"
    mv "$TMPDIR/vars.new" "$VARS_FILE"
    echo "PATCH: $VARS_FILE"
  fi

  # Remplacements occurrences
  for f in "${FILES_TO_PATCH[@]}"; do
    tmp="$TMPDIR/rep.$(basename "$f").$$"
    perl -0777 -pe "s/\\b${VAR_NAME}\\b/${NEW_VAR}/g" "$f" > "$tmp"
    if ! cmp -s "$f" "$tmp"; then
      mv "$tmp" "$f"
      echo "PATCH: $f"
    else
      rm -f "$tmp"
    fi
  done
  echo "✅ Terminé (apply)."
else
  echo
  echo "ℹ️  Dry-run uniquement. Ajoute --apply pour écrire les changements."
fi

