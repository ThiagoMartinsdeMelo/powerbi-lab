#Requires -RunAsAdministrator
#Requires -Version 5.1
<#
.SYNOPSIS
    Cria a estrutura de diretórios do laboratório Power BI.
.DESCRIPTION
    Cria pastas C:\PowerBI e subdiretórios para dados, projetos, SQL, etc.
#>

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\common-functions.ps1"

Invoke-SafeExecution -Description "Criação de diretórios" -ScriptBlock {
    $directories = @(
        "C:\PowerBI",
        "C:\PowerBI\Data",
        "C:\PowerBI\Projetos",
        "C:\PowerBI\SQL",
        "C:\PowerBI\Exports",
        "C:\PowerBI\MachineLearning",
        "C:\PowerBI\MachineLearning\notebooks",
        "C:\PowerBI\MachineLearning\models",
        "C:\PowerBI\MachineLearning\data",
        "C:\PowerBI\Templates",
        "C:\PowerBI\Templates\pbit",
        "C:\PowerBI\Templates\dax",
        "C:\PowerBI\Templates\powerquery",
        "C:\PowerBI\Templates\dashboards",
        "C:\PowerBI\Logs",
        "C:\PowerBI\Scripts"
    )

    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            Write-Log "Diretório criado: $dir" -Level "INFO"
        }
        else {
            Write-Log "Diretório já existe: $dir" -Level "INFO"
        }
    }

    Write-Log "Estrutura de diretórios criada com sucesso." -Level "SUCCESS"
}
