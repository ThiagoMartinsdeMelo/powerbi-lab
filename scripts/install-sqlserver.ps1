#Requires -RunAsAdministrator
#Requires -Version 5.1
<#
.SYNOPSIS
    Instala SQL Server Express e SSMS via Chocolatey.
#>

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\common-functions.ps1"

Invoke-SafeExecution -Description "Instalação SQL Server Express" -ScriptBlock {
    # SQL Server Express 2022
    Install-ChocoPackage -PackageName "sql-server-express" -ExtraArgs @(
        "--params",
        "'/SECURITYMODE=SQL /SAPWD=PowerBI@Lab2026! /TCPENABLED=1 /NPENABLED=1'"
    )

    # SQL Server Management Studio
    Install-ChocoPackage -PackageName "sql-server-management-studio"

    # Azure Data Studio
    Install-ChocoPackage -PackageName "azure-data-studio"

    # Habilitar protocolo TCP
    $instanceReg = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL" -ErrorAction SilentlyContinue
    $instanceId = $instanceReg.SQLEXPRESS
    $saPassword = "PowerBI@Lab2026!"

    if ($instanceId) {
        $sqlBrowserPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceId\MSSQLServer\SuperSocketNetLib\Tcp"
        if (Test-Path $sqlBrowserPath) {
            Set-ItemProperty -Path $sqlBrowserPath -Name "Enabled" -Value 1
            Write-Log "Protocolo TCP habilitado para SQL Server Express." -Level "SUCCESS"
        }

        # Mixed mode: necessario para login sa (Chocolatey pode instalar so Windows Auth)
        $loginModePath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceId\MSSQLServer"
        if (Test-Path $loginModePath) {
            Set-ItemProperty -Path $loginModePath -Name "LoginMode" -Value 2
            Write-Log "Autenticacao mista habilitada (LoginMode=2)." -Level "INFO"
        }
    }

    # Reiniciar serviço SQL Server
    $sqlService = Get-Service -Name "MSSQL`$SQLEXPRESS" -ErrorAction SilentlyContinue
    if ($sqlService) {
        Restart-Service -Name "MSSQL`$SQLEXPRESS" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 8
        Write-Log "Serviço SQL Server Express reiniciado." -Level "INFO"
    }

    $sqlCmd = "${env:ProgramFiles}\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\SQLCMD.EXE"
    if (-not (Test-Path $sqlCmd)) {
        $sqlCmd = (Get-ChildItem -Path "${env:ProgramFiles}\Microsoft SQL Server" -Filter "SQLCMD.EXE" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
    }

    if ($sqlCmd -and (Test-Path $sqlCmd)) {
        $prevEAP = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        $saSql = "IF EXISTS (SELECT 1 FROM sys.sql_logins WHERE name = 'sa') BEGIN ALTER LOGIN sa ENABLE; ALTER LOGIN sa WITH PASSWORD = N'$saPassword'; END"
        & $sqlCmd -S "localhost\SQLEXPRESS" -E -Q $saSql 2>&1 | Out-Null
        $ErrorActionPreference = $prevEAP

        if ($LASTEXITCODE -eq 0) {
            Write-Log "Login sa habilitado e senha configurada." -Level "SUCCESS"
        }
        else {
            Write-Log "Nao foi possivel configurar login sa (exit $LASTEXITCODE)." -Level "WARN"
        }
    }

    Write-Log "SQL Server Express e SSMS instalados." -Level "SUCCESS"
}
