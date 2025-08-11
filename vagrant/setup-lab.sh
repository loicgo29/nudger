Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"
  config.ssh.insert_key = false
  config.vm.synced_folder ".", "/vagrant", disabled: true

  NODES = [
    { hostname: "kubm1", cpus: 2, mem: 2048, ssh_port: 50210 }
  ]

  NODES.each do |node|
    config.vm.define node[:hostname] do |vm|
      vm.vm.hostname = node[:hostname]
      
      vm.vm.provider "qemu" do |q|
        q.memory = node[:mem]
        q.smp = node[:cpus]
        q.qemuargs = [
          ["-netdev", "user,id=net0,hostfwd=tcp::#{node[:ssh_port]}-:22"],
          ["-device", "virtio-net-pci,netdev=net0"]
        ]
      end

      # Provisionnement minimal pour avoir une VM fonctionnelle
      vm.vm.provision "shell", inline: <<-SHELL
        echo "vagrant:vagrant" | sudo chpasswd
        sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
        sudo systemctl restart sshd
      SHELL
    end
  end
end
