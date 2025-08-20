#!/bin/bash
set -e

echo "⚠️ Attention : ceci va supprimer tous les PVC/PV et namespaces XWiki/Longhorn bloqués !"

# 1️⃣ Supprimer tous les PVC terminés
for pvc in $(kubectl get pvc -A --no-headers | awk '{print $1":"$2}'); do
    ns=$(echo $pvc | cut -d: -f1)
    name=$(echo $pvc | cut -d: -f2)
    echo "Suppression forcée du PVC $name dans $ns"
    kubectl patch pvc $name -n $ns -p '{"metadata":{"finalizers":[]}}' --type=merge || true
    kubectl delete pvc $name -n $ns --grace-period=0 --force || true
done

# 2️⃣ Supprimer tous les PV qui sont bloqués
for pv in $(kubectl get pv --no-headers | awk '{print $1}'); do
    echo "Suppression forcée du PV $pv"
    kubectl patch pv $pv -p '{"metadata":{"finalizers":[]}}' --type=merge || true
    kubectl delete pv $pv --grace-period=0 --force || true
done

# 3️⃣ Supprimer les namespaces bloqués
for ns in nudger-xwiki open4goods longhorn-system; do
    echo "Suppression forcée du namespace $ns"
    kubectl get namespace $ns -o json > /tmp/ns.json || true
    if [ -f /tmp/ns.json ]; then
        jq '.spec.finalizers=[]' /tmp/ns.json > /tmp/ns-no-finalizers.json
        kubectl replace --raw "/api/v1/namespaces/$ns/finalize" -f /tmp/ns-no-finalizers.json || true
    fi
done

echo "✅ Nettoyage terminé"
kubectl get pvc,pv -A
kubectl get ns

