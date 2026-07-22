#Requires -RunAsAdministrator
#Requires -Version 5.1
<#
.SYNOPSIS
    Instala Git via Chocolatey.
#>

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\common-functions.ps1"

Invoke-SafeExecution -Description "Instalação Git" -ScriptBlock {
    function Test-GitAvailable {
        return [bool](Get-Command git -ErrorAction SilentlyContinue)
    }

    if (-not (Test-GitAvailable)) {
        $installed = Install-ChocoPackage -PackageName "git" -ExtraArgs @(
            "--params", "'/GitAndUnixToolsOnPath /WindowsTerminal'"
        )
        Refresh-EnvironmentPath

        if (-not $installed -and -not (Test-GitAvailable)) {
            Write-Log "Chocolatey falhou; tentando winget..." -Level "WARN"

            $prevEAP = $ErrorActionPreference
            $ErrorActionPreference = 'Continue'
            if (Get-Command winget -ErrorAction SilentlyContinue) {
                Start-Process -FilePath "winget" `
                    -ArgumentList @(
                        "install", "--id", "Git.Git", "-e",
                        "--accept-source-agreements", "--accept-package-agreements", "--silent"
                    ) `
                    -Wait -PassThru -NoNewWindow | Out-Null
            }
            $ErrorActionPreference = $prevEAP
            Refresh-EnvironmentPath
        }
    }
    else {
        Write-Log "Git já está disponível no PATH." -Level "INFO"
    }

    if (-not (Test-GitAvailable)) {
        Write-Log "Git não encontrado; configuração pulada." -Level "WARN"
        return
    }

    git config --system core.autocrlf true
    git config --system init.defaultBranch main
    Write-Log "Git configurado." -Level "SUCCESS"
}
