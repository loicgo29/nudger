# ~/.bashrc

# Charger les alias
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Charger fzf si installé
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# Charger le profil Kubernetes si dispo
if [ -f ~/nudger/config-vm/profile_logo.sh ]; then
    source ~/nudger/config-vm/profile_logo.sh
fi

