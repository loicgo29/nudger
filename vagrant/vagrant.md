```bash
vagrant destroy -f
vagrant up
ssh -p 2222 vagrant@127.0.0.1
```

En cas de modif mineure:
```bash
 vagrant provision
sed -i.bak 's/virtio-net-device/virtio-net-pci/' ~/.vagrant.d/gems/3.3.8/gems/vagrant-qemu-0.3.12/lib/vagrant-qemu/config.rb

