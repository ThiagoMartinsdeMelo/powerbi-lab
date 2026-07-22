#Requires -RunAsAdministrator
#Requires -Version 5.1
<#
.SYNOPSIS
    Instala DBeaver Community Edition via Chocolatey.
#>

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\common-functions.ps1"

Invoke-SafeExecution -Description "Instalação DBeaver" -ScriptBlock {
    Install-ChocoPackage -PackageName "dbeaver"
}
