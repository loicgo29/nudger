# GitOps (single-repo) – staging / prod
- Source unique: flux-system/GitRepository -> https://REPLACE_ME (main)
- Racines env: clusters/{staging,prod}
- Apps wrap: gitops/apps/<app>/base -> référence k8s-apps/<app> (pas de duplication)
- Sync: GitRepository=15m / Kustomization=30m

## Reconcilier
flux reconcile source git gitops -n flux-system
flux reconcile kustomization staging-root -n flux-system
flux reconcile kustomization prod-root -n flux-system
