#Requires -RunAsAdministrator
#Requires -Version 5.1
<#
.SYNOPSIS
    Instala MySQL Server e MySQL Workbench via Chocolatey.
#>

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\common-functions.ps1"

Invoke-SafeExecution -Description "Instalação MySQL" -ScriptBlock {
    $mysqlPassword = "PowerBI@Lab2026!"

    Install-ChocoPackage -PackageName "mysql" -ExtraArgs @(
        "--params",
        "'/port:3306 /password:$mysqlPassword'"
    )

    Install-ChocoPackage -PackageName "mysql.workbench"

    Refresh-EnvironmentPath

    # Iniciar serviço MySQL
    $mysqlService = Get-Service -Name "MySQL*" -ErrorAction SilentlyContinue
    if ($mysqlService) {
        Start-Service -Name $mysqlService.Name -ErrorAction SilentlyContinue
        Write-Log "Serviço MySQL iniciado: $($mysqlService.Name)" -Level "SUCCESS"
    }
}
