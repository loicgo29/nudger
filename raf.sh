#!/usr/bin/env bash
set -euo pipefail

# =========================
#  Paramètres personnalisables
# =========================
TARGET_DIR="${TARGET_DIR:-gitops}"                 # dossier racine de sortie
CLUSTER="${CLUSTER:-production}"                    # nom logique du cluster (répertoire clusters/<CLUSTER>)
GIT_URL="${GIT_URL:-ssh://git@github.com/OWNER/REPO.git}"  # URL du repo GitOps (SSH ou HTTPS)
BRANCH="${BRANCH:-main}"                            # branche Git à suivre
SYNC_INTERVAL="${SYNC_INTERVAL:-1m}"                # intervalle de sync GitRepository
KUSTOMIZE_INTERVAL="${KUSTOMIZE_INTERVAL:-10m}"     # intervalle de reconcil des Kustomizations
INGRESS_CLASS="${INGRESS_CLASS:-nginx}"             # classe d’ingress utilisée par l’exemple
WHOAMI_DOMAIN="${WHOAMI_DOMAIN:-whoami.example.com}"# hostname d’exemple (ingress)

# =========================
#  Helpers
# =========================
emit() { # emit <filepath> <heredoc-name>
  local path="$1"; shift
  mkdir -p "$(dirname "$path")"
  cat > "$path"
  echo "  + $path"
}

headline() { echo; echo "==> $*"; }

# =========================
#  Génération
# =========================
headline "Structure de base"
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

# -------- flux-system (référencement du repo GitOps) --------
headline "flux-system (GitRepository + Kustomization)"
emit "clusters/${CLUSTER}/flux-system/gitrepository.yaml" <<EOF
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: cluster
  namespace: flux-system
spec:
  interval: ${SYNC_INTERVAL}
  url: ${GIT_URL}
  ref:
    branch: ${BRANCH}
  # secretRef:
  #   name: flux-system   # (si tu utilises un secret SSH pour le repo)
EOF

emit "clusters/${CLUSTER}/flux-system/kustomization.yaml" <<EOF
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: cluster-root
  namespace: flux-system
spec:
  interval: ${KUSTOMIZE_INTERVAL}
  prune: true
  sourceRef:
    kind: GitRepository
    name: cluster
  path: ./clusters/${CLUSTER}/root
  wait: true
  timeout: 5m
EOF

# -------- racine de cluster (assemble infra + apps) --------
headline "root (assemble infra + apps)"
emit "clusters/${CLUSTER}/root/kustomization.yaml" <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../infra
  - ../apps
EOF

# -------- Infra: namespaces, HelmRepository, HelmRelease --------
headline "Infra (namespaces, sources Helm, releases)"
# Namespaces
emit "clusters/${CLUSTER}/infra/namespaces/ingress-nginx/namespace.yaml" <<'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: ingress-nginx
EOF

emit "clusters/${CLUSTER}/infra/namespaces/ingress-nginx/kustomization.yaml" <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources: [namespace.yaml]
EOF

emit "clusters/${CLUSTER}/infra/namespaces/cert-manager/namespace.yaml" <<'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: cert-manager
EOF

emit "clusters/${CLUSTER}/infra/namespaces/cert-manager/kustomization.yaml" <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources: [namespace.yaml]
EOF

# Helm repositories (Flux Source)
emit "clusters/${CLUSTER}/infra/sources/helm/ingress-nginx-helmrepo.yaml" <<'EOF'
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: ingress-nginx
  namespace: flux-system
spec:
  interval: 10m
  url: https://kubernetes.github.io/ingress-nginx
EOF

emit "clusters/${CLUSTER}/infra/sources/helm/jetstack-helmrepo.yaml" <<'EOF'
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: jetstack
  namespace: flux-system
spec:
  interval: 10m
  url: https://charts.jetstack.io
EOF

# Helm releases (Flux Helm Controller)
emit "clusters/${CLUSTER}/infra/releases/ingress-nginx/helmrelease.yaml" <<EOF
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: ingress-nginx
  namespace: ingress-nginx
spec:
  interval: ${KUSTOMIZE_INTERVAL}
  chart:
    spec:
      chart: ingress-nginx
      version: "4.*"
      sourceRef:
        kind: HelmRepository
        name: ingress-nginx
        namespace: flux-system
  values:
    controller:
      ingressClassResource:
        name: ${INGRESS_CLASS}
        default: true
      service:
        type: NodePort
        # Pour un vrai LB: change en LoadBalancer (ou garde NodePort + LB externe)
EOF

emit "clusters/${CLUSTER}/infra/releases/ingress-nginx/kustomization.yaml" <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources: [helmrelease.yaml]
EOF

emit "clusters/${CLUSTER}/infra/releases/cert-manager/helmrelease.yaml" <<'EOF'
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: cert-manager
  namespace: cert-manager
spec:
  interval: 10m
  chart:
    spec:
      chart: cert-manager
      version: "v1.*"
      sourceRef:
        kind: HelmRepository
        name: jetstack
        namespace: flux-system
  values:
    installCRDs: true
EOF

emit "clusters/${CLUSTER}/infra/releases/cert-manager/kustomization.yaml" <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources: [helmrelease.yaml]
EOF

# Kustomization d’agrégation de toute l’infra
emit "clusters/${CLUSTER}/infra/kustomization.yaml" <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - namespaces/ingress-nginx
  - namespaces/cert-manager
  - sources/helm/ingress-nginx-helmrepo.yaml
  - sources/helm/jetstack-helmrepo.yaml
  - releases/ingress-nginx
  - releases/cert-manager
EOF

# -------- Apps (exemple whoami, base + overlay cluster) --------
headline "Apps (exemple whoami)"
# Namespace commun pour apps
emit "clusters/${CLUSTER}/apps/namespaces/apps/namespace.yaml" <<'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: apps
EOF

emit "clusters/${CLUSTER}/apps/namespaces/apps/kustomization.yaml" <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources: [namespace.yaml]
EOF

# App whoami base
emit "apps/whoami/base/deployment.yaml" <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: whoami
  labels: { app: whoami }
spec:
  replicas: 1
  selector:
    matchLabels: { app: whoami }
  template:
    metadata:
      labels: { app: whoami }
    spec:
      containers:
        - name: whoami
          image: traefik/whoami:v1.10.2
          ports:
            - containerPort: 80
EOF

emit "apps/whoami/base/service.yaml" <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: whoami
spec:
  selector: { app: whoami }
  ports:
    - port: 80
      targetPort: 80
      protocol: TCP
      name: http
  type: ClusterIP
EOF

emit "apps/whoami/base/kustomization.yaml" <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
EOF

# Overlay lié au cluster: namespace + Ingress d’exemple
emit "apps/whoami/overlays/${CLUSTER}/ingress.yaml" <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: whoami
  annotations:
    kubernetes.io/ingress.class: "${INGRESS_CLASS}"
spec:
  rules:
    - host: "${WHOAMI_DOMAIN}"
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: whoami
                port:
                  number: 80
EOF

emit "apps/whoami/overlays/${CLUSTER}/kustomization.yaml" <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: apps
resources:
  - ../../base
  - ingress.yaml
EOF

# Kustomization d’agrégation des apps pour le cluster
emit "clusters/${CLUSTER}/apps/kustomization.yaml" <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - namespaces/apps
  - ../../apps/whoami/overlays/${CLUSTER}
EOF

headline "Résumé"
echo "Arborescence générée dans: $(pwd)"
echo
# Affichage rapide (sans dépendre de tree)
find . -maxdepth 6 -type f | sed 's|^\./||' | sort

cat <<'EONEXT'

Prochaines étapes :
1) Installer les contrôleurs Flux sur le cluster (une fois kubeconfig OK) :
   flux install

2) Créer le secret d’accès au repo si besoin (SSH ou HTTPS+token) :
   # SSH :
   kubectl -n flux-system create secret generic flux-system \
     --from-file=identity=/path/to/id_ed25519 \
     --from-file=identity.pub=/path/to/id_ed25519.pub \
     --from-file=known_hosts=/etc/ssh/ssh_known_hosts

   # HTTPS + PAT :
   kubectl -n flux-system create secret generic flux-system \
     --from-literal=username=git \
     --from-literal=password=$GITHUB_TOKEN

3) Commit & push ce dossier vers ton repo GitOps :
   git init && git remote add origin <${GIT_URL}>
   git checkout -b ${BRANCH}
   git add .
   git commit -m "Initial GitOps skeleton (${CLUSTER})"
   git push -u origin ${BRANCH}

4) Laisser Flux réconcilier :
   kubectl -n flux-system get kustomizations
   kubectl -n flux-system get gitrepositories
   kubectl -n ingress-nginx get pods
   kubectl -n cert-manager get pods

Remarques :
- Le GitRepository/Kustomization Flux pointent vers: ${GIT_URL}#${BRANCH}, path clusters/${CLUSTER}/root
- ingress-nginx est en NodePort par défaut (modifie en LoadBalancer si tu as un LB).
- L’app “whoami” publie une Ingress sur ${WHOAMI_DOMAIN}. Change le domaine ou supprime l’Ingress si inutile.
- Tu peux ajouter d’autres apps sous apps/<name>/base + overlays/<cluster> et les référencer dans clusters/${CLUSTER}/apps/kustomization.yaml.
EONEXT

