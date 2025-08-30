#!/usr/bin/env bash
set -euo pipefail

# ------------ Paramètres (tes défauts) ------------
TARGET_DIR="${TARGET_DIR:-gitops}"
ENVS=(${ENVS:-staging prod})
BRANCH="${BRANCH:-main}"
GIT_URL="${GIT_URL:-}"  # ssh://git@github.com/OWNER/REPO.git ou https://github.com/OWNER/REPO.git
SYNC_INTERVAL="${SYNC_INTERVAL:-15m}"
KUSTOMIZE_INTERVAL="${KUSTOMIZE_INTERVAL:-30m}"
INGRESS_CLASS="${INGRESS_CLASS:-nginx}"
DOMAIN_BASE="${DOMAIN_BASE:-example.com}"

# Apps à embarquer (adapter à ta repo)
APPS=(${APPS:-nudger-xwiki})   # ajoute d'autres noms d'apps séparés par des espaces

# ------------ Arbo flux-system / clusters ------------
mkdir -p "${TARGET_DIR}/flux-system"
for ENV in "${ENVS[@]}"; do
  mkdir -p "${TARGET_DIR}/clusters/${ENV}"
done

# ------------ GitRepository + Kustomization par env ------------
cat > "${TARGET_DIR}/flux-system/gitrepository.yaml" <<YAML
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: gitops
  namespace: flux-system
spec:
  interval: ${SYNC_INTERVAL}
  url: ${GIT_URL:-"https://REPLACE_ME"}
  ref:
    branch: ${BRANCH}
YAML

for ENV in "${ENVS[@]}"; do
cat > "${TARGET_DIR}/flux-system/kustomization-${ENV}.yaml" <<YAML
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: ${ENV}-root
  namespace: flux-system
spec:
  interval: ${KUSTOMIZE_INTERVAL}
  sourceRef:
    kind: GitRepository
    name: gitops
  path: ./clusters/${ENV}
  prune: true
  wait: false
YAML
done

# ------------ Racines des environnements ------------
for ENV in "${ENVS[@]}"; do
  cat > "${TARGET_DIR}/clusters/${ENV}/kustomization.yaml" <<YAML
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
$(for app in "${APPS[@]}"; do echo "  - ../../apps/${app}/overlays/${ENV}"; done)
YAML
done

# ------------ Wrap apps existantes (sans déplacer k8s-apps) ------------
for APP in "${APPS[@]}"; do
  # base qui référence ta source existante
  mkdir -p "${TARGET_DIR}/apps/${APP}/base"
  cat > "${TARGET_DIR}/apps/${APP}/base/kustomization.yaml" <<YAML
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../../../k8s-apps/${APP}
YAML

  # overlays env avec ingress générique
  for ENV in "${ENVS[@]}"; do
    mkdir -p "${TARGET_DIR}/apps/${APP}/overlays/${ENV}"
    cat > "${TARGET_DIR}/apps/${APP}/overlays/${ENV}/kustomization.yaml" <<'YAML'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../base
patches:
  # Ajoute ici des patchesStrategicMerge ou JSON6902 pour overrides par env
  # - path: patch.yaml
YAML

    # Ingress de base (optionnel, supprime si géré dans k8s-apps/${APP})
    cat > "${TARGET_DIR}/apps/${APP}/overlays/${ENV}/ingress.yaml" <<YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${APP}
  annotations:
    kubernetes.io/ingress.class: "${INGRESS_CLASS}"
spec:
  rules:
    - host: "${APP}.${ENV}.${DOMAIN_BASE}"
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: ${APP}
                port:
                  number: 80
YAML

    # Si le Service de l'app n'est pas "APP:80", on ne référence pas l'ingress par défaut
    # sinon on l'ajoute
    if grep -q "name: ${APP}" "${TARGET_DIR}/apps/${APP}/overlays/${ENV}/ingress.yaml" 2>/dev/null; then
      # recharge le Kustomization pour inclure l'ingress
      cat > "${TARGET_DIR}/apps/${APP}/overlays/${ENV}/kustomization.yaml" <<YAML
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../base
  - ingress.yaml
YAML
    fi
  done
done

# ------------ README ------------
cat > "${TARGET_DIR}/README.md" <<EOF
# GitOps (single-repo) – staging / prod
- Source unique: flux-system/GitRepository -> ${GIT_URL:-"https://REPLACE_ME"} (${BRANCH})
- Racines env: clusters/{staging,prod}
- Apps wrap: gitops/apps/<app>/base -> référence k8s-apps/<app> (pas de duplication)
- Sync: GitRepository=${SYNC_INTERVAL} / Kustomization=${KUSTOMIZE_INTERVAL}

## Reconcilier
flux reconcile source git gitops -n flux-system
flux reconcile kustomization staging-root -n flux-system
flux reconcile kustomization prod-root -n flux-system
EOF

echo "✅ GitOps scaffold prêt dans ${TARGET_DIR}"
