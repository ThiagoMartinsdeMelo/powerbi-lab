#Requires -Version 5.1
<#
.SYNOPSIS
    Funções reutilizáveis para provisionamento do PowerBI Lab.
.DESCRIPTION
    Módulo comum dot-sourced por todos os scripts de instalação.
    Fornece logging, verificação de instalação e tratamento de erros.
#>

# Diretório base de logs
$script:LogDirectory = "C:\PowerBI\Logs"
$script:LogFile = Join-Path $script:LogDirectory "provision.log"

function Initialize-Logging {
    <#
    .SYNOPSIS
        Inicializa o diretório e arquivo de log de provisionamento.
    #>
    if (-not (Test-Path $script:LogDirectory)) {
        New-Item -Path $script:LogDirectory -ItemType Directory -Force | Out-Null
    }
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $script:LogFile -Value "`n[$timestamp] === Iniciando script: $($MyInvocation.ScriptName) ==="
}

function Write-Log {
    <#
    .SYNOPSIS
        Escreve mensagem no console e no arquivo de log.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    switch ($Level) {
        "INFO"    { Write-Host $logEntry -ForegroundColor White }
        "WARN"    { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR"   { Write-Host $logEntry -ForegroundColor Red }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
    }

    if (Test-Path (Split-Path $script:LogFile -Parent)) {
        Add-Content -Path $script:LogFile -Value $logEntry
    }
}

function Test-CommandExists {
    <#
    .SYNOPSIS
        Verifica se um comando está disponível no PATH.
    #>
    param([Parameter(Mandatory = $true)][string]$CommandName)
    return [bool](Get-Command $CommandName -ErrorAction SilentlyContinue)
}

function Test-ChocoPackageInstalled {
    <#
    .SYNOPSIS
        Verifica se um pacote Chocolatey já está instalado.
    #>
    param([Parameter(Mandatory = $true)][string]$PackageName)

    if (-not (Test-CommandExists "choco")) {
        return $false
    }

    $result = choco list --local-only $PackageName --exact 2>$null
    return ($result -match "^$PackageName\s")
}

function Install-ChocoPackage {
    <#
    .SYNOPSIS
        Instala pacote via Chocolatey com verificação de idempotência.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageName,

        [string[]]$ExtraArgs = @()
    )

    if (Test-ChocoPackageInstalled -PackageName $PackageName) {
        Write-Log "$PackageName já está instalado. Pulando." -Level "INFO"
        return $true
    }

    Write-Log "Instalando $PackageName via Chocolatey..." -Level "INFO"

    $args = @("install", $PackageName, "-y", "--no-progress") + $ExtraArgs
    $process = Start-Process -FilePath "choco" -ArgumentList $args -Wait -PassThru -NoNewWindow

    if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
        Write-Log "$PackageName instalado com sucesso." -Level "SUCCESS"
        return $true
    }

    Write-Log "Falha ao instalar $PackageName. ExitCode: $($process.ExitCode)" -Level "ERROR"
    return $false
}

function Invoke-SafeExecution {
    <#
    .SYNOPSIS
        Executa scriptblock com tratamento de erro centralizado.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $true)]
        [string]$Description
    )

    try {
        Write-Log "Iniciando: $Description" -Level "INFO"
        & $ScriptBlock
        Write-Log "Concluído: $Description" -Level "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Erro em '$Description': $($_.Exception.Message)" -Level "ERROR"
        Write-Log "StackTrace: $($_.ScriptStackTrace)" -Level "ERROR"
        throw
    }
}

function Get-VagrantScriptPath {
    <#
    .SYNOPSIS
        Retorna caminho do diretório de scripts sincronizado pelo Vagrant.
    #>
    $paths = @("C:\vagrant\scripts", "\\vagrant\scripts", "C:\PowerBI\Scripts")
    foreach ($path in $paths) {
        if (Test-Path $path) { return $path }
    }
    return "C:\vagrant\scripts"
}

function Get-VagrantDataPath {
    <#
    .SYNOPSIS
        Retorna caminho do diretório de dados sincronizado pelo Vagrant.
    #>
    $paths = @("C:\vagrant\data", "\\vagrant\data", "C:\PowerBI\Data")
    foreach ($path in $paths) {
        if (Test-Path $path) { return $path }
    }
    return "C:\vagrant\data"
}

function Get-VagrantSqlPath {
    <#
    .SYNOPSIS
        Retorna caminho do diretório SQL sincronizado pelo Vagrant.
    #>
    $paths = @("C:\vagrant\sql", "\\vagrant\sql", "C:\PowerBI\SQL")
    foreach ($path in $paths) {
        if (Test-Path $path) { return $path }
    }
    return "C:\vagrant\sql"
}

function Refresh-EnvironmentPath {
    <#
    .SYNOPSIS
        Atualiza variáveis de ambiente PATH na sessão atual.
    #>
    $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machinePath;$userPath"
}

# Inicializar logging ao dot-source
Initialize-Logging
