#Requires -RunAsAdministrator
#Requires -Version 5.1
<#
.SYNOPSIS
    Instala PostgreSQL e pgAdmin via Chocolatey.
#>

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\common-functions.ps1"

Invoke-SafeExecution -Description "Instalação PostgreSQL" -ScriptBlock {
    function Set-PostgresLabPassword {
        param(
            [Parameter(Mandatory = $true)][string]$Password,
            [Parameter(Mandatory = $true)][string]$PgBin
        )

        $psql = Join-Path $PgBin "psql.exe"
        $env:PGPASSWORD = $Password

        $prevEAP = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        & $psql -h 127.0.0.1 -U postgres -c "SELECT 1;" 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $ErrorActionPreference = $prevEAP
            Write-Log "Senha postgres ja valida." -Level "INFO"
            return $true
        }

        $hbaFile = Get-ChildItem "${env:ProgramFiles}\PostgreSQL" -Recurse -Filter "pg_hba.conf" -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if (-not $hbaFile) {
            $ErrorActionPreference = $prevEAP
            Write-Log "pg_hba.conf nao encontrado; senha postgres nao configurada." -Level "WARN"
            return $false
        }

        $hbaPath = $hbaFile.FullName
        $hbaBackup = "$hbaPath.bak.powerbilab"
        Copy-Item $hbaPath $hbaBackup -Force

        @"
# Temporary trust for PowerBI Lab password reset
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust
host    all             all             ::1/128                 trust
"@ | Set-Content -Path $hbaPath -Encoding ASCII

        $pgService = Get-Service -Name "postgresql*" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($pgService) {
            Restart-Service $pgService.Name -Force
            Start-Sleep -Seconds 5
        }

        $alterSql = "ALTER USER postgres WITH PASSWORD '$Password';"
        & $psql -h 127.0.0.1 -U postgres -c $alterSql 2>&1 | Out-Null
        $resetOk = ($LASTEXITCODE -eq 0)

        Copy-Item $hbaBackup $hbaPath -Force
        Remove-Item $hbaBackup -Force -ErrorAction SilentlyContinue

        if ($pgService) {
            Restart-Service $pgService.Name -Force
            Start-Sleep -Seconds 5
        }

        $env:PGPASSWORD = $Password
        & $psql -h 127.0.0.1 -U postgres -c "SELECT 1;" 2>&1 | Out-Null
        $verified = ($LASTEXITCODE -eq 0)
        $ErrorActionPreference = $prevEAP

        if ($verified) {
            Write-Log "Senha postgres configurada para o laboratorio." -Level "SUCCESS"
            return $true
        }

        Write-Log "Nao foi possivel configurar senha postgres (reset=$resetOk)." -Level "WARN"
        return $false
    }

    $pgPassword = "PowerBI@Lab2026!"
    $pgService = Get-Service -Name "postgresql*" -ErrorAction SilentlyContinue

    $pgBin = "${env:ProgramFiles}\PostgreSQL\16\bin"
    if (-not (Test-Path "$pgBin\psql.exe")) {
        $pgBin = (Get-ChildItem -Path "${env:ProgramFiles}\PostgreSQL" -Filter "psql.exe" -Recurse -ErrorAction SilentlyContinue |
            Select-Object -First 1).DirectoryName
    }

    if ($pgService -or ($pgBin -and (Test-Path "$pgBin\psql.exe"))) {
        Write-Log "PostgreSQL ja instalado. Pulando Chocolatey." -Level "INFO"
    }
    else {
        $chocoParams = "/Password:`"$pgPassword`" /Port:5432 /NoServerMode"
        Install-ChocoPackage -PackageName "postgresql16" -ExtraArgs @("--params", $chocoParams)
    }

    if (-not (Test-ChocoPackageInstalled -PackageName "pgadmin4")) {
        Install-ChocoPackage -PackageName "pgadmin4"
    }
    else {
        Write-Log "pgadmin4 ja instalado. Pulando." -Level "INFO"
    }

    Refresh-EnvironmentPath

    if ($pgService) {
        Start-Service -Name $pgService.Name -ErrorAction SilentlyContinue
        Write-Log "Servico PostgreSQL iniciado: $($pgService.Name)" -Level "SUCCESS"
    }

    if ($pgBin -and (Test-Path "$pgBin\psql.exe")) {
        Set-PostgresLabPassword -Password $pgPassword -PgBin $pgBin | Out-Null
    }
}
