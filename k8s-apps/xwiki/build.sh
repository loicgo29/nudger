#!/usr/bin/env bash
set -euo pipefail

# Variables
CHART_DIR="./"
VALUES_FILE="minimal_values.yaml"
NAMESPACE="open4goods"
KUSTOMIZE_DIR="kustomize"
RENDERED_FILE="$KUSTOMIZE_DIR/rendered.yaml"

ACTION=${1:-apply} # apply | delete | create | diff

echo "=== [1/4] Génération du rendu Helm ==="
helm template xwiki "$CHART_DIR" -f "$VALUES_FILE" -n "$NAMESPACE" > "$RENDERED_FILE"

echo "=== [2/4] Nettoyage des probes 'exec' en doublon ==="
yq 'del(.. | .exec?)' "$RENDERED_FILE" -i

echo "=== [3/4] Construction avec Kustomize ==="
kustomize build "$KUSTOMIZE_DIR" > "$KUSTOMIZE_DIR/final.yaml"

echo "=== [4/4] kubectl $ACTION ==="
case "$ACTION" in
  apply)
    kubectl apply -f "$KUSTOMIZE_DIR/final.yaml" 
    ;;
  create)
    kubectl create -f "$KUSTOMIZE_DIR/final.yaml"
    ;;
  delete)
    kubectl delete -f "$KUSTOMIZE_DIR/final.yaml"
    ;;
  diff)
    kubectl diff -f "$KUSTOMIZE_DIR/final.yaml"
    ;;
  *)
    echo "Usage: $0 [apply|create|delete|diff]"
    exit 1
    ;;
esac

