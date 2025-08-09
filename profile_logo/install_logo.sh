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
