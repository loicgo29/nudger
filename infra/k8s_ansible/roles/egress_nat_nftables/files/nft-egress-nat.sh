#!/usr/bin/env bash
set -euo pipefail

POD_CIDR="${1:-10.244.0.0/24}"
SVC_CIDR="${2:-10.96.0.0/12}"

# Interface de sortie "WAN"
WAN_IF=$(ip route get 1.1.1.1 | awk '{for(i=1;i<=NF;i++) if ($i=="dev"){print $(i+1); exit}}')
[ -n "${WAN_IF:-}" ] || { echo "WAN_IF introuvable"; exit 1; }

# Assure l'existence des tables/chaînes
nft list table ip nat >/dev/null 2>&1 || nft 'add table ip nat'
nft 'add chain ip nat POSTROUTING { type nat hook postrouting priority 100 ; }' 2>/dev/null || true
nft 'add chain ip filter FORWARD { type filter hook forward priority 0 ; }' 2>/dev/null || true

# Règles FORWARD (idempotentes)
nft add rule ip filter FORWARD ct state related,established accept 2>/dev/null || true
nft add rule ip filter FORWARD ip saddr $POD_CIDR accept 2>/dev/null || true

# NAT : ne pas SNAT l’intra-cluster, puis masquerade vers Internet
nft add rule ip nat POSTROUTING ip saddr $POD_CIDR ip daddr $SVC_CIDR return 2>/dev/null || true
nft add rule ip nat POSTROUTING ip saddr $POD_CIDR oif $WAN_IF masquerade 2>/dev/null || true

echo "[egress-nat] OK : POD_CIDR=$POD_CIDR, SVC_CIDR=$SVC_CIDR, WAN_IF=$WAN_IF"
