# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "debian/bookworm64"
  config.ssh.insert_key = false
  
  # Desabilita o DHCP nativo do VirtualBox
  config.trigger.before :"Vagrant::Action::Builtin::WaitForCommunicator", type: :action do |t|
    t.warn = "Interrompendo o servidor DHCP do VirtualBox..."
    t.run = { inline: "vboxmanage dhcpserver stop --interface vboxnet0" }
  end

  config.vm.provider "virtualbox" do |v|
    v.memory = 512
    v.linked_clone = true
    v.check_guest_additions = false
  end

  # Servidor de Arquivos (arq)
  config.vm.define "arq" do |arq|
    arq.vm.hostname = "arq.jesse.joao.devops"
    arq.vm.network "private_network", ip: "192.168.56.109"
    (1..3).each { |i|
      arq.vm.disk :disk, size: "10GB", name: "disk-#{i}" } # 3 discos extras
  end

  # Servidor de Banco de Dados (db)
  config.vm.define "db" do |db|
    db.vm.hostname = "db.jesse.joao.devops"
    db.vm.network "private_network", type: "dhcp", mac: "0800273A0001" # MAC para IP estático no DHCP
  end

  # Servidor de Aplicação (app)
  config.vm.define "app" do |app|
    app.vm.hostname = "app.jesse.joao.devops"
    app.vm.network "private_network", type: "dhcp", mac: "0800273A0002"
  end

  # Host Cliente (cli)
  config.vm.define "cli" do |cli|
    cli.vm.hostname = "cli.jesse.joao.devops"
    cli.vm.memory = 1024 # RAM diferenciada
    cli.vm.network "private_network", type: "dhcp"
  end
end