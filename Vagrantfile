# Vaprobash is a handy friend!
# https://github.com/fideloper/Vaprobash

hostname        = "puppet.dev"
server_ip       = "192.168.22.98"
server_cpus     = "2"
server_memory   = "2048"

Vagrant.configure("2") do |config|

  config.vm.box = "hfm4/centos7"

  if Vagrant.has_plugin?("vagrant-hostmanager")
    config.hostmanager.enabled = true
    config.hostmanager.manage_host = true
    config.hostmanager.ignore_private_ip = false
    config.hostmanager.include_offline = false
  end

  config.vm.hostname = hostname
  config.vm.network :private_network, ip: server_ip
  config.vm.network :forwarded_port, guest: 80, host: 8999
  config.vm.network :forwarded_port, guest: 8081, host: 8998
  config.vm.synced_folder "./", "/etc/puppet"

  config.vm.provider :virtualbox do |vb|
    vb.name = hostname + "-001"
    vb.customize ["guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 10000]
    vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/v-root", "1" ]
    vb.customize ["showvminfo", :id ]
    vb.customize ["modifyvm", :id, "--cpus", server_cpus]
    vb.customize ["modifyvm", :id, "--memory", server_memory]

    # Prevent VMs running on Ubuntu to lose internet connection
    # vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    # vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
  end

  # Provision Base Packages
  config.vm.provision "shell", path: "install_puppet.sh", args: ["/etc/puppet"]
end