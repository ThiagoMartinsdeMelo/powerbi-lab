# -*- coding: utf-8 -*-
# PowerBI Lab - Vagrantfile
# Provisiona automaticamente um ambiente Windows 11 com Power BI Desktop
# e stack completa de Business Intelligence / Data Analytics.

Vagrant.configure("2") do |config|
  # Box pública Windows 11 (VirtualBox) — mantida e atualizada no Vagrant Cloud
  # Documentação: https://packer.gusztavvargadr.me/images/windows-11/latest/
  config.vm.box = "gusztavvargadr/windows-11"
  config.vm.box_version = "2601.0.0"

  config.vm.hostname = "powerbi"

  # Rede privada com IP fixo para acesso consistente
  config.vm.network "private_network", ip: "192.168.56.100"

  # Sincronização de pastas do host para a VM.
  # Apenas a raiz do projeto — data/, scripts/ e sql/ já ficam em /vagrant/*.
  # Syncs aninhados (./sql -> /vagrant/sql) conflitam no Windows: o mount pai
  # cria /vagrant/sql como diretório comum e o segundo mount falha ao criar junction.
  config.vm.synced_folder ".", "/vagrant", type: "virtualbox"

  # WinRM - comunicação com a VM Windows
  config.vm.communicator = "winrm"
  config.winrm.username = "vagrant"
  config.winrm.password = "vagrant"
  config.winrm.timeout = 7200
  config.winrm.retry_limit = 30
  config.winrm.retry_delay = 10
  # Evita erro "Digest initialization failed" em boxes gusztavvargadr (OpenSSL 3+)
  config.winrm.transport = :plaintext
  config.winrm.basic_auth_only = true

  config.vm.boot_timeout = 1800
  config.vm.graceful_halt_timeout = 600

  config.vm.provider "virtualbox" do |vb|
    vb.name = "PowerBI-Lab"
    vb.memory = 8192
    vb.cpus = 4
    vb.gui = true

    # Disco de 80 GB
    vb.customize ["modifyvm", :id, "--vram", "128"]
    vb.customize ["modifyvm", :id, "--graphicscontroller", "vboxsvga"]
    vb.customize ["modifyvm", :id, "--accelerate3d", "on"]

    # Disco de 80 GB (resize após primeira criação se necessário)
    # vagrant disk resize --disk primary --size 81920
  end

  # Ordem de provisionamento - cada etapa depende da anterior
  # Nota: configure-winrm.ps1 omitido — a box gusztavvargadr já vem com WinRM configurado
  $scripts = [
    "install-chocolatey.ps1",
    "create-directories.ps1",
    "copy-datasets.ps1",
    "install-git.ps1",
    "install-vscode.ps1",
    "install-dbeaver.ps1",
    "install-powerbi.ps1",
    "install-sqlserver.ps1",
    "install-postgresql.ps1",
    "install-mysql.ps1",
    "install-python.ps1",
    "setup-databases.ps1",
    "setup-powerbi-templates.ps1",
    "setup-jupyter-notebooks.ps1"
  ]

  $scripts.each do |script|
    # privileged: true executa via scheduled task como administrador (Vagrant 2.4+)
    config.vm.provision "shell", privileged: true, inline: <<-SHELL
      $ErrorActionPreference = 'Stop'
      $ScriptPath = "C:\\vagrant\\scripts\\#{script}"
      if (-not (Test-Path $ScriptPath)) {
        $ScriptPath = "\\\\vagrant\\scripts\\#{script}"
      }
      Write-Host "========================================" -ForegroundColor Cyan
      Write-Host " Executando: #{script}" -ForegroundColor Cyan
      Write-Host "========================================" -ForegroundColor Cyan
      & $ScriptPath
    SHELL
  end
end
