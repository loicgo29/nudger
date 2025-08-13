#!/bin/bash

# ==============================================
# SCRIPT D'INSTALLATION DE LA CONFIGURATION DEVOPS
# ==============================================
 sudo apt update && sudo apt install -y \
    git curl wget jq tree unzip \
    bash-completion make tar gzip

git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --all
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*') && \
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" && \
    tar xf lazygit.tar.gz lazygit && \
    sudo install lazygit /usr/local/bin \
    rm -rf lazygit.tar.gz lazygit
