#!/bin/zsh

###############################################################
#  TITRE: 
#
#  AUTEUR:   Loic G.
#  VERSION: 
#  CREATION:  
#  MODIFIE: 
#
#  DESCRIPTION: 
###############################################################



# Variables ###################################################



# Functions ###################################################



# Let's Go !! #################################################

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=100000
HISTFILESIZE=20000

alias ll='ls -laFh --color=auto'
alias la='ls -A'
alias l='ls -larth'
alias gl='git log'
alias gst='git status'
alias gg='git log --oneline --all --graph --name-status'
alias s='sudo -s'
alias h='helm'
alias k='kubectl'
alias kcc='kubectl config current-context'
alias kg='kubectl get'
alias kga='kubectl get all --all-namespaces'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kn='kubens'
alias ksgp='kubectl get pods -n kube-system'
alias kss='kubectl get services -n kube-system'
alias kuc='kubectl config use-context'
alias kx='kubectx'
alias vu='vagrant up'


# ================================
# ⚡ Mise à jour de ~/.zshrc pour Ansible
# ================================
ZSHRC="$HOME/.zshrc"
ANSIBLE_VENV="$HOME/ansible_venv"

# Vérifie si la ligne d'activation du venv existe déjà
if ! grep -q "source $ANSIBLE_VENV/bin/activate" "$ZSHRC"; then
    echo "🔹 Ajout de l'activation automatique du venv Ansible dans ~/.zshrc"
    {
        echo ""
        echo "# Activer automatiquement le venv Ansible"
        echo "if [ -d \"$ANSIBLE_VENV\" ]; then"
        echo "    source \"$ANSIBLE_VENV/bin/activate\""
        echo "fi"
    } >> "$ZSHRC"
fi

# Vérifie si l'alias pour le playbook existe déjà
if ! grep -q "alias k8s-setup=" "$ZSHRC"; then
    echo "🔹 Ajout de l'alias k8s-setup dans ~/.zshrc"
    echo "" >> "$ZSHRC"
    echo "alias k8s-setup='ansible-playbook -i ~/nudger/nudger-infra/k8s-ansible/inventory.ini ~/nudger/nudger-infra/k8s-ansible/playbooks/kubernetes-setup.yml'" >> "$ZSHRC"
fi
echo "✅ ~/.zshrc mis à jour. Ouvre un nouveau terminal ou lance 'source ~/.zshrc' pour appliquer."


clear
echo -e '\033[0;32m
██╗░░░░░░█████╗░░██████╗░░█████╗░
██║░░░░░██╔══██╗██╔════╝░██╔══██╗
██║░░░░░██║░░██║██║░░██╗░██║░░██║
██║░░░░░██║░░██║██║░░╚██╗██║░░██║
███████╗╚█████╔╝╚██████╔╝╚█████╔╝
╚══════╝░╚════╝░░╚═════╝░░╚════╝░
'
export KUBECONFIG=/home/vagrant/.k0s/kubeconfig
