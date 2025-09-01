#!/usr/bin/env bash
set -euo pipefail

INV_FILE="${INV_FILE:-/Users/loicgourmelon/Devops/nudger/infra/k8s_ansible/inventory.ini}"
HOST="${1:-master1}"

if [[ ! -f "$INV_FILE" ]]; then
  echo "Inventory introuvable: $INV_FILE" >&2
  exit 1
fi

# Extrait la ligne de l'hôte (ignore commentaires et lignes vides)
line="$(awk -v h="$HOST" '
  /^[[:space:]]*#/ { next }
  /^[[:space:]]*$/ { next }
  $1 == h { print; exit }
' "$INV_FILE")"

if [[ -z "${line:-}" ]]; then
  echo "Hôte '$HOST' introuvable dans $INV_FILE" >&2
  exit 1
fi

# Parse les paires key=value (gère chemins avec / et ~)
declare -A kv
# shellcheck disable=SC2206
parts=($line) # split sur espaces
for p in "${parts[@]}"; do
  # ne garder que les segments contenant '=' (les autres sont le nom d'hôte ou groupes)
  if [[ "$p" == *"="* ]]; then
    k="${p%%=*}"
    v="${p#*=}"
    # retire d'éventuelles quotes
    v="${v%\"}"; v="${v#\"}"
    v="${v%\'}"; v="${v#\'}"
    kv["$k"]="$v"
  fi
done

ip="${kv[ansible_host]:-}"
user="${kv[ansible_user]:-root}"
key="${kv[ansible_ssh_private_key_file]:-}"

if [[ -z "$ip" ]]; then
  echo "ansible_host manquant pour $HOST" >&2
  exit 1
fi

ssh_args=()
if [[ -n "$key" ]]; then
  # expand ~ si présent
  eval key_expanded="$key"
  ssh_args+=(-i "$key_expanded")
fi

echo "→ SSH vers ${user}@${ip} ${key:+(clé: $key)}"
echo "${ssh_args[@]} -o StrictHostKeyChecking=accept-new ${user}@${ip}"
exec ssh "${ssh_args[@]}" -o StrictHostKeyChecking=accept-new "${user}@${ip}"
