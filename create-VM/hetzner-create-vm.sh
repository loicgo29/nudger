hcloud ssh-key create --name loic-vm-key --public-key "$(cat ~/.ssh/id_vm_ed25519.pub)"

hcloud server create \
  --name nudger-vm-k8s \
  --image ubuntu-22.04 \
  --type cpx21 \
  --user-data-from-file ./cloud-init.yaml 

