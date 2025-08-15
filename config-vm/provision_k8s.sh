#!/bin/bash
set -e

echo "🔹 Provisioning Kubernetes environment..."

# Mettre à jour les paquets
sudo apt update -y
sudo apt upgrade -y

# Installer outils nécessaires
sudo apt install -y bash-completion curl git

# Installer kubectl si non présent
if ! command -v kubectl &>/dev/null; then
    echo "🔹 Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
fi

# Installer helm si non présent
if ! command -v helm &>/dev/null; then
    echo "🔹 Installing helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# Créer profile_logo.sh
cat << 'EOF' > /home/vagrant/profile_logo.sh
#!/bin/bash
echo -e '\033[0;32m'
cat << "BANNER"
██╗░░░░░░█████╗░░██████╗░░█████╗░
██║░░░░░██╔══██╗██╔════╝░██╔══██╗
██║░░░░░██║░░██║██║░░██╗░██║░░██║
██║░░░░░██║░░██║██║░░╚██╗██║░░██║
███████╗╚█████╔╝╚██████╔╝╚█████╔╝
╚══════╝░╚════╝░░╚═════╝░░╚════╝░
BANNER
echo -e '\033[0m'

export KUBECONFIG="/home/vagrant/.k0s/kubeconfig"
HISTCONTROL=ignoredups:erasedups
HISTSIZE=100000
HISTFILESIZE=200000

alias ll='ls -laFh --color=auto'
alias la='ls -A'
alias l='ls -larth'
alias s='sudo -s'
alias k='kubectl'
alias kcc='kubectl config current-context'
alias kg='kubectl get'
alias kga='kubectl get all --all-namespaces'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias ksgp='kubectl get pods -n kube-system'
alias kss='kubectl get services -n kube-system'
alias kuc='kubectl config use-context'
alias vu='vagrant up'

if command -v kubectl &>/dev/null; then
    source <(kubectl completion bash)
    complete -F __start_kubectl k
fi

echo "✅ Kubernetes environment ready!"
EOF

chmod +x /home/vagrant/profile_logo.sh
chown vagrant:vagrant /home/vagrant/profile_logo.sh

# Modifier .bashrc pour charger le profil
if ! grep -q "profile_logo.sh" /home/vagrant/.bashrc; then
    echo "source ~/profile_logo.sh" >> /home/vagrant/.bashrc
fi

echo "✅ Provisioning complete."
#Vagrant.configure("2") do |config|
#  config.vm.box = "ubuntu/focal64"
#  config.vm.provision "shell", path: "provision_k8s.sh"
#end
