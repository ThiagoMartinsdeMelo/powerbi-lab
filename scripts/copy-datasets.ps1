#Requires -RunAsAdministrator
#Requires -Version 5.1
<#
.SYNOPSIS
    Copia datasets CSV do host para C:\PowerBI\Data.
.DESCRIPTION
    Copia arquivos de /vagrant/data para o diretório de dados local na VM.
#>

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\common-functions.ps1"

Invoke-SafeExecution -Description "Cópia de datasets" -ScriptBlock {
    $sourcePath = Get-VagrantDataPath
    $destPath = "C:\PowerBI\Data"

    if (-not (Test-Path $destPath)) {
        New-Item -Path $destPath -ItemType Directory -Force | Out-Null
    }

    $datasets = @(
        "vendas.csv", "marketing.csv", "financeiro.csv",
        "rh.csv", "logistica.csv", "contabilidade.csv", "acoes.csv"
    )

    foreach ($file in $datasets) {
        $source = Join-Path $sourcePath $file
        $dest = Join-Path $destPath $file

        if (Test-Path $source) {
            Copy-Item -Path $source -Destination $dest -Force
            $lineCount = (Get-Content $dest | Measure-Object -Line).Lines - 1
            Write-Log "Copiado: $file ($lineCount registros)" -Level "SUCCESS"
        }
        else {
            Write-Log "Arquivo não encontrado: $source" -Level "WARN"
        }
    }

    # Copiar scripts SQL
    $sqlSource = Get-VagrantSqlPath
    if (Test-Path $sqlSource) {
        Copy-Item -Path "$sqlSource\*" -Destination "C:\PowerBI\SQL" -Recurse -Force
        Write-Log "Scripts SQL copiados para C:\PowerBI\SQL" -Level "SUCCESS"
    }
}
