#Requires -RunAsAdministrator
#Requires -Version 5.1
<#
.SYNOPSIS
    Configura WinRM para provisionamento remoto via Vagrant.
.DESCRIPTION
    Habilita e configura WinRM com autenticação básica e HTTPS opcional.
    Este script é executado como primeiro passo do provisionamento.
#>

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\common-functions.ps1"

Invoke-SafeExecution -Description "Configuração WinRM" -ScriptBlock {
    Write-Log "Configurando serviço WinRM..." -Level "INFO"

    # Habilitar PS Remoting
    Enable-PSRemoting -Force -SkipNetworkProfileCheck

    # Configurar WinRM para aceitar conexões
    winrm quickconfig -quiet -force
    winrm set winrm/config/service/auth '@{Basic="true"}'
    winrm set winrm/config/service '@{AllowUnencrypted="true"}'
    winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="1024"}'
    winrm set winrm/config '@{MaxTimeoutms="7200000"}'

    # Firewall - liberar WinRM
    Set-NetFirewallRule -Name "WINRM-HTTP-In-TCP" -Enabled True -ErrorAction SilentlyContinue
    netsh advfirewall firewall add rule name="WinRM-HTTP" dir=in action=allow protocol=TCP localport=5985 2>$null

    # Configurar TrustedHosts para Vagrant
    Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force

    # Reiniciar serviço WinRM
    Restart-Service WinRM -Force

    # Definir hostname
    Rename-Computer -NewName "powerbi" -Force -ErrorAction SilentlyContinue

    Write-Log "WinRM configurado com sucesso." -Level "SUCCESS"
}
