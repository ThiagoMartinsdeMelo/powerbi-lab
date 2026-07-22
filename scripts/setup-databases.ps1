#Requires -RunAsAdministrator
#Requires -Version 5.1
<#
.SYNOPSIS
    Importa datasets CSV para SQL Server, PostgreSQL e MySQL.
.DESCRIPTION
    Executa scripts SQL de criação e importa dados via BULK INSERT,
    COPY e LOAD DATA INFILE respectivamente.
#>

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\common-functions.ps1"

Invoke-SafeExecution -Description "Setup bancos de dados" -ScriptBlock {
    $dataPath = "C:\PowerBI\Data"
    $sqlPath = "C:\PowerBI\SQL"
    $dbPassword = "PowerBI@Lab2026!"

    function Invoke-SqlCmdInputFile {
        param(
            [Parameter(Mandatory = $true)][string]$SqlCmdPath,
            [Parameter(Mandatory = $true)][string]$ServerInstance,
            [Parameter(Mandatory = $true)][string]$InputFile,
            [Parameter(Mandatory = $true)][string]$SaPassword
        )

        $prevEAP = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'

        # Provisionamento roda como admin; Windows Auth e o caminho mais confiavel.
        & $SqlCmdPath -S $ServerInstance -E -i $InputFile 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $ErrorActionPreference = $prevEAP
            return $true
        }

        & $SqlCmdPath -S $ServerInstance -U sa -P $SaPassword -i $InputFile 2>&1 | Out-Null
        $ok = ($LASTEXITCODE -eq 0)
        $ErrorActionPreference = $prevEAP
        return $ok
    }

    # =========================================================
    # SQL SERVER
    # =========================================================
    Write-Log "Configurando SQL Server..." -Level "INFO"

    $sqlServerInstance = "localhost\SQLEXPRESS"
    $sqlCmd = "${env:ProgramFiles}\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\SQLCMD.EXE"

    if (-not (Test-Path $sqlCmd)) {
        $sqlCmd = (Get-ChildItem -Path "${env:ProgramFiles}\Microsoft SQL Server" -Filter "SQLCMD.EXE" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
    }

    if ($sqlCmd -and (Test-Path $sqlCmd)) {
        # Executar scripts de criação
        $sqlScripts = @("create_database.sql", "northwind.sql", "adventureworks.sql")
        foreach ($script in $sqlScripts) {
            $scriptPath = Join-Path $sqlPath $script
            if (Test-Path $scriptPath) {
                if (Invoke-SqlCmdInputFile -SqlCmdPath $sqlCmd -ServerInstance $sqlServerInstance -InputFile $scriptPath -SaPassword $dbPassword) {
                    Write-Log "Script SQL executado: $script" -Level "SUCCESS"
                }
                else {
                    Write-Log "Falha ao executar script SQL: $script" -Level "WARN"
                }
            }
        }

        # Importar CSVs via BULK INSERT
        $tables = @{
            "vendas.csv"         = "Vendas"
            "marketing.csv"      = "Marketing"
            "financeiro.csv"     = "Financeiro"
            "rh.csv"             = "RH"
            "logistica.csv"      = "Logistica"
            "contabilidade.csv"  = "Contabilidade"
            "acoes.csv"          = "Acoes"
        }

        foreach ($csv in $tables.Keys) {
            $csvPath = Join-Path $dataPath $csv
            $tableName = $tables[$csv]
            if (Test-Path $csvPath) {
                $bulkSql = @"
USE PowerBILab;
BULK INSERT dbo.$tableName
FROM '$csvPath'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK,
    CODEPAGE = '65001'
);
"@
                $tempSql = Join-Path $env:TEMP "bulk_$tableName.sql"
                Set-Content -Path $tempSql -Value $bulkSql -Encoding UTF8
                if (Invoke-SqlCmdInputFile -SqlCmdPath $sqlCmd -ServerInstance $sqlServerInstance -InputFile $tempSql -SaPassword $dbPassword) {
                    Write-Log "Importado para SQL Server: $tableName" -Level "SUCCESS"
                }
                else {
                    Write-Log "Falha ao importar para SQL Server: $tableName" -Level "WARN"
                }
            }
        }
    }
    else {
        Write-Log "SQLCMD não encontrado. Importação SQL Server pulada." -Level "WARN"
    }

    function Invoke-PsqlCommand {
        param(
            [Parameter(Mandatory = $true)][string]$PgBin,
            [Parameter(Mandatory = $true)][string]$DbPassword,
            [Parameter(Mandatory = $true)][string[]]$PsqlArgs
        )

        $env:PGPASSWORD = $DbPassword
        $prevEAP = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        & "$PgBin\psql.exe" -h 127.0.0.1 @PsqlArgs 2>&1 | Out-Null
        $ok = ($LASTEXITCODE -eq 0)
        $ErrorActionPreference = $prevEAP
        return $ok
    }

    # =========================================================
    # POSTGRESQL
    # =========================================================
    Write-Log "Configurando PostgreSQL..." -Level "INFO"

    $pgBin = "${env:ProgramFiles}\PostgreSQL\16\bin"
    if (-not (Test-Path $pgBin)) {
        $pgBin = (Get-ChildItem -Path "${env:ProgramFiles}\PostgreSQL" -Filter "psql.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1).DirectoryName
    }

    $pgCreateSql = @"
CREATE TABLE IF NOT EXISTS vendas (
    id INT PRIMARY KEY, data_venda DATE, produto VARCHAR(100), regiao VARCHAR(50),
    quantidade INT, preco_unitario DECIMAL(18,2), valor_total DECIMAL(18,2),
    canal VARCHAR(50), codigo_pedido VARCHAR(20)
);
CREATE TABLE IF NOT EXISTS marketing (
    id INT PRIMARY KEY, data_campanha DATE, canal VARCHAR(50), regiao VARCHAR(50),
    investimento DECIMAL(18,2), impressoes INT, conversoes INT,
    taxa_conversao DECIMAL(10,2), departamento VARCHAR(50)
);
CREATE TABLE IF NOT EXISTS financeiro (
    id INT PRIMARY KEY, data_lancamento DATE, regiao VARCHAR(50),
    receita DECIMAL(18,2), despesa DECIMAL(18,2), lucro DECIMAL(18,2),
    margem_percentual DECIMAL(10,2), mes VARCHAR(10), ano INT
);
CREATE TABLE IF NOT EXISTS rh (
    id INT PRIMARY KEY, nome VARCHAR(100), cargo VARCHAR(50), departamento VARCHAR(50),
    regiao VARCHAR(50), salario DECIMAL(18,2), data_admissao DATE,
    status VARCHAR(20), idade INT
);
CREATE TABLE IF NOT EXISTS logistica (
    id INT PRIMARY KEY, data_envio DATE, pedido VARCHAR(20), transportadora VARCHAR(50),
    origem VARCHAR(50), destino VARCHAR(50), peso_kg DECIMAL(10,2),
    custo_frete DECIMAL(18,2), dias_entrega INT, status VARCHAR(20)
);
CREATE TABLE IF NOT EXISTS contabilidade (
    id INT PRIMARY KEY, data_lancamento DATE, conta VARCHAR(100), tipo VARCHAR(10),
    valor DECIMAL(18,2), regiao VARCHAR(50), documento VARCHAR(20), centro_custo VARCHAR(50)
);
CREATE TABLE IF NOT EXISTS acoes (
    id INT PRIMARY KEY, data DATE, ticker VARCHAR(10), empresa VARCHAR(100),
    abertura DECIMAL(18,2), maxima DECIMAL(18,2), minima DECIMAL(18,2),
    fechamento DECIMAL(18,2), volume BIGINT, variacao_percentual DECIMAL(10,2)
);
"@

    if ($pgBin -and (Test-Path "$pgBin\psql.exe")) {
        if (-not (Invoke-PsqlCommand -PgBin $pgBin -DbPassword $dbPassword -PsqlArgs @("-U", "postgres", "-c", "CREATE DATABASE powerbi_lab;"))) {
            Invoke-PsqlCommand -PgBin $pgBin -DbPassword $dbPassword -PsqlArgs @("-U", "postgres", "-c", "SELECT 1 FROM pg_database WHERE datname = 'powerbi_lab';") | Out-Null
        }

        if (-not (Invoke-PsqlCommand -PgBin $pgBin -DbPassword $dbPassword -PsqlArgs @("-U", "postgres", "-d", "powerbi_lab", "-c", $pgCreateSql))) {
            Write-Log "Falha ao criar tabelas PostgreSQL." -Level "WARN"
        }

        $pgTables = @("vendas", "marketing", "financeiro", "rh", "logistica", "contabilidade", "acoes")
        foreach ($table in $pgTables) {
            $csvFile = Join-Path $dataPath "$table.csv"
            if (Test-Path $csvFile) {
                $pgCsvPath = $csvFile -replace '\\', '/'
                if (Invoke-PsqlCommand -PgBin $pgBin -DbPassword $dbPassword -PsqlArgs @(
                        "-U", "postgres", "-d", "powerbi_lab", "-c",
                        "\COPY $table FROM '$pgCsvPath' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')"
                    )) {
                    Write-Log "Importado para PostgreSQL: $table" -Level "SUCCESS"
                }
                else {
                    Write-Log "Falha ao importar PostgreSQL: $table" -Level "WARN"
                }
            }
        }
    }
    else {
        Write-Log "PostgreSQL psql não encontrado. Importação pulada." -Level "WARN"
    }

    # =========================================================
    # MYSQL
    # =========================================================
    Write-Log "Configurando MySQL..." -Level "INFO"

    $mysqlBin = "${env:ProgramFiles}\MySQL\MySQL Server 8.0\bin"
    if (-not (Test-Path $mysqlBin)) {
        $mysqlBin = (Get-ChildItem -Path "${env:ProgramFiles}\MySQL" -Filter "mysql.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1).DirectoryName
    }

    if ($mysqlBin -and (Test-Path "$mysqlBin\mysql.exe")) {
        function Invoke-MySqlCommand {
            param(
                [Parameter(Mandatory = $true)][string[]]$MySqlArgs
            )

            $prevEAP = $ErrorActionPreference
            $ErrorActionPreference = 'Continue'
            & "$mysqlBin\mysql.exe" @MySqlArgs 2>&1 | Out-Null
            $ok = ($LASTEXITCODE -eq 0)
            $ErrorActionPreference = $prevEAP
            return $ok
        }

        $mysqlCreateSql = @"
CREATE DATABASE IF NOT EXISTS powerbi_lab;
USE powerbi_lab;

CREATE TABLE IF NOT EXISTS vendas (
    id INT PRIMARY KEY, data_venda DATE, produto VARCHAR(100), regiao VARCHAR(50),
    quantidade INT, preco_unitario DECIMAL(18,2), valor_total DECIMAL(18,2),
    canal VARCHAR(50), codigo_pedido VARCHAR(20)
);
CREATE TABLE IF NOT EXISTS marketing (
    id INT PRIMARY KEY, data_campanha DATE, canal VARCHAR(50), regiao VARCHAR(50),
    investimento DECIMAL(18,2), impressoes INT, conversoes INT,
    taxa_conversao DECIMAL(10,2), departamento VARCHAR(50)
);
CREATE TABLE IF NOT EXISTS financeiro (
    id INT PRIMARY KEY, data_lancamento DATE, regiao VARCHAR(50),
    receita DECIMAL(18,2), despesa DECIMAL(18,2), lucro DECIMAL(18,2),
    margem_percentual DECIMAL(10,2), mes VARCHAR(10), ano INT
);
CREATE TABLE IF NOT EXISTS rh (
    id INT PRIMARY KEY, nome VARCHAR(100), cargo VARCHAR(50), departamento VARCHAR(50),
    regiao VARCHAR(50), salario DECIMAL(18,2), data_admissao DATE,
    status VARCHAR(20), idade INT
);
CREATE TABLE IF NOT EXISTS logistica (
    id INT PRIMARY KEY, data_envio DATE, pedido VARCHAR(20), transportadora VARCHAR(50),
    origem VARCHAR(50), destino VARCHAR(50), peso_kg DECIMAL(10,2),
    custo_frete DECIMAL(18,2), dias_entrega INT, status VARCHAR(20)
);
CREATE TABLE IF NOT EXISTS contabilidade (
    id INT PRIMARY KEY, data_lancamento DATE, conta VARCHAR(100), tipo VARCHAR(10),
    valor DECIMAL(18,2), regiao VARCHAR(50), documento VARCHAR(20), centro_custo VARCHAR(50)
);
CREATE TABLE IF NOT EXISTS acoes (
    id INT PRIMARY KEY, data DATE, ticker VARCHAR(10), empresa VARCHAR(100),
    abertura DECIMAL(18,2), maxima DECIMAL(18,2), minima DECIMAL(18,2),
    fechamento DECIMAL(18,2), volume BIGINT, variacao_percentual DECIMAL(10,2)
);
"@

        $tempMysqlSql = Join-Path $env:TEMP "create_mysql.sql"
        Set-Content -Path $tempMysqlSql -Value $mysqlCreateSql -Encoding UTF8
        if (-not (Invoke-MySqlCommand -MySqlArgs @("-u", "root", "-p$dbPassword", "-e", "source $tempMysqlSql"))) {
            Write-Log "Falha ao criar schema MySQL (verifique senha root)." -Level "WARN"
        }

        $mysqlTables = @("vendas", "marketing", "financeiro", "rh", "logistica", "contabilidade", "acoes")
        foreach ($table in $mysqlTables) {
            $csvFile = Join-Path $dataPath "$table.csv"
            if (Test-Path $csvFile) {
                $mysqlCsvPath = $csvFile -replace '\\', '/'
                $loadSql = @"
USE powerbi_lab; LOAD DATA INFILE '$mysqlCsvPath' INTO TABLE $table FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
"@
                if (Invoke-MySqlCommand -MySqlArgs @("-u", "root", "-p$dbPassword", "-e", $loadSql)) {
                    Write-Log "Importado para MySQL: $table" -Level "SUCCESS"
                }
                else {
                    Write-Log "Falha ao importar MySQL: $table" -Level "WARN"
                }
            }
        }
    }
    else {
        Write-Log "MySQL client não encontrado. Importação pulada." -Level "WARN"
    }

    Write-Log "Setup de bancos de dados concluído." -Level "SUCCESS"
}
