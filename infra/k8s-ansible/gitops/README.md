# GitOps (single-repo)
- GitRepository -> https://REPLACE_ME (branch main)
- Envs: lab
- Flux sync: GitRepository=15m, Kustomization=1m
- Apps: nudger-xwiki

## Reconcile (exemples)
flux reconcile source git gitops -n flux-system
flux reconcile kustomization lab-root -n flux-system
