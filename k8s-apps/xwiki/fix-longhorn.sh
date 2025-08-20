#!/bin/bash

NAMESPACE="longhorn-system"

echo "=== 1️⃣ Supprimer les pods problématiques pour forcer leur recréation ==="
kubectl delete pod -n $NAMESPACE -l app=longhorn-csi-plugin
kubectl delete pod -n $NAMESPACE -l app=engine-image-ei
kubectl delete pod -n $NAMESPACE -l app=longhorn-manager
kubectl delete pod -n $NAMESPACE -l app=csi-provisioner
kubectl delete pod -n $NAMESPACE -l app=csi-attacher
kubectl delete pod -n $NAMESPACE -l app=csi-resizer
kubectl delete pod -n $NAMESPACE -l app=csi-snapshotter

echo
echo "=== 2️⃣ Réappliquer Longhorn complet ==="
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.9.1/deploy/longhorn.yaml

echo
echo "=== 3️⃣ Vérifier que tous les pods sont Running ==="
kubectl get pods -n $NAMESPACE

echo
echo "=== 4️⃣ Vérifier le PVC XWiki/MySQL ==="
kubectl get pvc -n open4goods
kubectl describe pvc data-xwiki-mysql-0 -n open4goods

