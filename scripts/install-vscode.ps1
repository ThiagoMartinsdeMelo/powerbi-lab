#Requires -RunAsAdministrator
#Requires -Version 5.1
<#
.SYNOPSIS
    Instala Visual Studio Code via Chocolatey.
#>

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\common-functions.ps1"

Invoke-SafeExecution -Description "Instalação VS Code" -ScriptBlock {
    Install-ChocoPackage -PackageName "vscode"

    $extensions = @(
        "ms-python.python",
        "ms-python.vscode-pylance",
        "ms-toolsai.jupyter",
        "ms-mssql.mssql",
        "cweijan.vscode-postgresql-client2",
        "formulahendry.vscode-mysql",
        "RandomFractalsInc.vscode-data-preview"
    )

    Refresh-EnvironmentPath
    $codePath = "${env:ProgramFiles}\Microsoft VS Code\bin\code.cmd"

    if (Test-Path $codePath) {
        foreach ($ext in $extensions) {
            # code.cmd escreve avisos Node.js em stderr; com Stop isso vira erro fatal.
            $prevEAP = $ErrorActionPreference
            $ErrorActionPreference = 'Continue'
            & $codePath --install-extension $ext --force 2>&1 | Out-Null
            $exitCode = $LASTEXITCODE
            $ErrorActionPreference = $prevEAP

            if ($exitCode -ne 0) {
                Write-Log "Falha ao instalar extensão: $ext (exit $exitCode)" -Level "WARN"
            }
            else {
                Write-Log "Extensão instalada: $ext" -Level "INFO"
            }
        }
    }
}
