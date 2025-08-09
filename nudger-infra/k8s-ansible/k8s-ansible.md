Installer le plugin YAML callback :
echo 'export PATH=$PATH:$HOME/.local/bin' >> ~/.bashrc
source ~/.bashrc
ansible-galaxy collection install community.general
ansible-galaxy collection install ansible.posix
ansible-galaxy collection install ansible.posix
ansible-galaxy collection install community.general

ansible all -m file -a "path=/root/.ansible/tmp state=directory mode=0775 owner=root group=root" -b


