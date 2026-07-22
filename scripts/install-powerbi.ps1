#Requires -RunAsAdministrator
#Requires -Version 5.1
<#
.SYNOPSIS
    Instala Power BI Desktop via Chocolatey.
#>

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\common-functions.ps1"

Invoke-SafeExecution -Description "Instalação Power BI Desktop" -ScriptBlock {
    # Pacote oficial no Chocolatey Community
    $installed = Install-ChocoPackage -PackageName "powerbi"

    if (-not $installed) {
        Write-Log "Tentando pacote alternativo microsoft-powerbi-desktop..." -Level "WARN"
        Install-ChocoPackage -PackageName "powerbi-desktop"
    }

    # Atalho na área de trabalho
    $pbiPath = "${env:ProgramFiles}\Microsoft Power BI Desktop\bin\PBIDesktop.exe"
    if (Test-Path $pbiPath) {
        $desktopPath = [Environment]::GetFolderPath("Desktop")
        $shortcutPath = Join-Path $desktopPath "Power BI Desktop.lnk"
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $pbiPath
        $shortcut.Save()
        Write-Log "Atalho Power BI Desktop criado na área de trabalho." -Level "SUCCESS"
    }
}
