# GitOps (single-repo)
- GitRepository -> https://REPLACE_ME (branch main)
- Envs: staging, prod
- Flux sync: GitRepository=15m, Kustomization=30m
- Apps: nudger-xwiki

## Reconcile (exemples)
flux reconcile source git gitops -n flux-system
flux reconcile kustomization staging-root -n flux-system
flux reconcile kustomization prod-root -n flux-system
