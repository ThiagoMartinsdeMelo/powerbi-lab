#Requires -RunAsAdministrator
#Requires -Version 5.1
<#
.SYNOPSIS
    Instala o Chocolatey Package Manager.
.DESCRIPTION
    Instala Chocolatey se não estiver presente e configura política de execução.
#>

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\common-functions.ps1"

Invoke-SafeExecution -Description "Instalação Chocolatey" -ScriptBlock {
    if (Test-CommandExists "choco") {
        Write-Log "Chocolatey já está instalado." -Level "INFO"
        choco upgrade chocolatey -y --no-progress
        return
    }

    Write-Log "Instalando Chocolatey..." -Level "INFO"

    # Process scope basta aqui; Vagrant ja roda com -ExecutionPolicy Bypass.
    # LocalMachine falha em boxes gusztavvargadr (policy efetiva vem de GPO).
    Set-ExecutionPolicy Bypass -Scope Process -Force

    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

    $installScript = Join-Path $env:TEMP "install-chocolatey.ps1"
    Invoke-WebRequest -Uri "https://community.chocolatey.org/install.ps1" -OutFile $installScript -UseBasicParsing
    & $installScript

    Refresh-EnvironmentPath

    if (Test-CommandExists "choco") {
        Write-Log "Chocolatey instalado com sucesso." -Level "SUCCESS"
        choco feature enable -n allowGlobalConfirmation
    }
    else {
        throw "Falha na instalação do Chocolatey."
    }
}
