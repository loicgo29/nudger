#!/bin/bash

# Fonction pour vérifier si une commande existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Vérifier si on est root ou sudo
if [ "$(id -u)" -ne 0 ]; then
    echo "Ce script doit être exécuté en tant que root ou avec sudo"
    exit 1
fi

# 1. Vérifier et charger br_netfilter
echo "[1/4] Vérification du module br_netfilter..."
if ! lsmod | grep -q br_netfilter; then
    echo " - Chargement du module br_netfilter..."
    if ! modprobe br_netfilter; then
        echo "ERREUR: Impossible de charger br_netfilter"
        exit 1
    fi
else
    echo " - br_netfilter est déjà chargé"
fi

# 2. Configurer bridge-nf-call-iptables
echo "[2/4] Configuration de net.bridge.bridge-nf-call-iptables..."
CURRENT_VALUE=$(sysctl -n net.bridge.bridge-nf-call-iptables 2>/dev/null)
if [ "$CURRENT_VALUE" != "1" ]; then
    echo " - Application de la configuration..."
    if ! sysctl net.bridge.bridge-nf-call-iptables=1; then
        echo "ERREUR: Impossible de configurer bridge-nf-call-iptables"
        exit 1
    fi
else
    echo " - La configuration est déjà active"
fi

# 3. Rendre la configuration persistante
echo "[3/4] Vérification de la persistance de la configuration..."
CONF_FILE="/etc/sysctl.d/99-kubernetes.conf"
CONF_LINE="net.bridge.bridge-nf-call-iptables = 1"

if [ ! -f "$CONF_FILE" ] || ! grep -qF "$CONF_LINE" "$CONF_FILE"; then
    echo " - Création du fichier de configuration..."
    echo "$CONF_LINE" | tee "$CONF_FILE" >/dev/null
    echo " - Application des paramètres sysctl..."
    if ! sysctl --system; then
        echo "ERREUR: Impossible d'appliquer les paramètres sysctl"
        exit 1
    fi
else
    echo " - La configuration est déjà persistante"
fi

# 4. Redémarrer Flannel si kubectl est disponible et Flannel est installé
echo "[4/4] Vérification de Flannel..."
if command_exists kubectl; then
    if kubectl get ns kube-flannel >/dev/null 2>&1; then
        echo " - Redémarrage des pods Flannel..."
        if ! kubectl delete pod -n kube-flannel -l app=flannel; then
            echo "ATTENTION: Impossible de redémarrer les pods Flannel"
        fi
    else
        echo " - Namespace kube-flannel non trouvé, Flannel n'est probablement pas installé"
    fi
else
    echo " - kubectl non trouvé, étape de redémarrage Flannel ignorée"
fi

echo "✅ Configuration terminée avec succès"
