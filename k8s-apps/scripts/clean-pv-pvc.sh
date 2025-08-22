#!/bin/bash
set -e

# Liste des namespaces à forcer
NAMESPACES=("nudger-xwiki" "open4goods" "longhorn-system")

echo "🚀 Nettoyage des PVC, PV et namespaces bloqués..."

# Supprimer les finalizers et forcer la suppression des PVC
for ns in "${NAMESPACES[@]}"; do
    echo "🔹 Traitement des PVC dans le namespace $ns"
    PVCs=$(kubectl get pvc -n $ns --no-headers -o custom-columns=":metadata.name" 2>/dev/null || true)
    for pvc in $PVCs; do
        kubectl patch pvc "$pvc" -n "$ns" -p '{"metadata":{"finalizers":[]}}' --type=merge || true
        kubectl delete pvc "$pvc" -n "$ns" --grace-period=0 --force || true
    done
done

# Supprimer les finalizers et forcer la suppression des PV
echo "🔹 Traitement des PV"
PVs=$(kubectl get pv --no-headers -o custom-columns=":metadata.name" 2>/dev/null || true)
for pv in $PVs; do
    kubectl patch pv "$pv" -p '{"metadata":{"finalizers":[]}}' --type=merge || true
    kubectl delete pv "$pv" --grace-period=0 --force || true
done

# Supprimer les finalizers et forcer la suppression des namespaces
echo "🔹 Traitement des namespaces"
for ns in "${NAMESPACES[@]}"; do
    JSON_TMP="/tmp/ns-${ns}-no-finalizers.json"
    kubectl get ns "$ns" -o json 2>/dev/null | jq '.spec.finalizers=[]' > "$JSON_TMP" 2>/dev/null || continue
    kubectl replace --raw "/api/v1/namespaces/$ns/finalize" -f "$JSON_TMP" 2>/dev/null || true
done

echo "✅ Nettoyage terminé."

