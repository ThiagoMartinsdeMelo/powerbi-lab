#Requires -RunAsAdministrator
#Requires -Version 5.1
<#
.SYNOPSIS
    Cria templates Power BI, exemplos DAX e scripts Power Query M.
#>

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\common-functions.ps1"

Invoke-SafeExecution -Description "Setup templates Power BI" -ScriptBlock {
    $templatesPath = "C:\PowerBI\Templates"

    # =========================================================
    # EXEMPLOS DAX
    # =========================================================
    $daxExamples = @"
// ============================================================
// PowerBI Lab - Exemplos de Medidas DAX
// ============================================================

// --- MEDIDAS DE VENDAS ---

Total Vendas =
SUM(Vendas[valor_total])

Quantidade Vendida =
SUM(Vendas[quantidade])

Ticket Médio =
DIVIDE([Total Vendas], DISTINCTCOUNT(Vendas[codigo_pedido]), 0)

Vendas YTD =
TOTALYTD([Total Vendas], DimDate[FullDate])

Vendas Ano Anterior =
CALCULATE([Total Vendas], SAMEPERIODLASTYEAR(DimDate[FullDate]))

Crescimento YoY =
DIVIDE([Total Vendas] - [Vendas Ano Anterior], [Vendas Ano Anterior], 0)

// --- MEDIDAS DE MARKETING ---

Total Investimento =
SUM(Marketing[investimento])

ROI Marketing =
DIVIDE([Total Vendas], [Total Investimento], 0)

Custo por Conversão =
DIVIDE([Total Investimento], SUM(Marketing[conversoes]), 0)

Taxa Conversão Média =
AVERAGE(Marketing[taxa_conversao])

// --- MEDIDAS FINANCEIRAS ---

Total Receita =
SUM(Financeiro[receita])

Total Despesa =
SUM(Financeiro[despesa])

Lucro Líquido =
SUM(Financeiro[lucro])

Margem Média =
AVERAGE(Financeiro[margem_percentual])

// --- MEDIDAS DE RH ---

Total Funcionários =
COUNTROWS(RH)

Salário Médio =
AVERAGE(RH[salario])

Funcionários Ativos =
CALCULATE(COUNTROWS(RH), RH[status] = "Ativo")

Custo Folha =
SUMX(FILTER(RH, RH[status] = "Ativo"), RH[salario])

// --- MEDIDAS DE AÇÕES ---

Preço Médio Fechamento =
AVERAGE(Acoes[fechamento])

Volume Total Negociado =
SUM(Acoes[volume])

Variação Média =
AVERAGE(Acoes[variacao_percentual])

Top Ticker =
CALCULATE(
    MAX(Acoes[ticker]),
    TOPN(1, ALL(Acoes[ticker]), SUM(Acoes[volume]), DESC)
)

// --- MEDIDAS AVANÇADAS ---

Ranking Produto =
RANKX(ALL(Vendas[produto]), [Total Vendas], , DESC, Dense)

Participação Regional =
DIVIDE(
    [Total Vendas],
    CALCULATE([Total Vendas], ALL(Vendas[regiao])),
    0
)

Média Móvel 7 Dias =
AVERAGEX(
    DATESINPERIOD(DimDate[FullDate], MAX(DimDate[FullDate]), -7, DAY),
    [Total Vendas]
)
"@
    Set-Content -Path "$templatesPath\dax\medidas-exemplo.dax" -Value $daxExamples -Encoding UTF8

    # =========================================================
    # EXEMPLOS POWER QUERY M
    # =========================================================
    $powerQueryExamples = @"
// ============================================================
// PowerBI Lab - Exemplos Power Query M
// ============================================================

// --- CONEXÃO SQL SERVER ---
let
    Source = Sql.Database("localhost\SQLEXPRESS", "PowerBILab"),
    Vendas = Source{[Schema="dbo",Item="Vendas"]}[Data],
    TypedVendas = Table.TransformColumnTypes(Vendas,{
        {"data_venda", type date},
        {"quantidade", Int64.Type},
        {"preco_unitario", Currency.Type},
        {"valor_total", Currency.Type}
    })
in
    TypedVendas

// --- CONEXÃO POSTGRESQL ---
let
    Source = PostgreSQL.Database("localhost", "powerbi_lab"),
    Vendas = Source{[Schema="public",Item="vendas"]}[Data]
in
    Vendas

// --- CONEXÃO MYSQL ---
let
    Source = MySQL.Database("localhost", "powerbi_lab"),
    Vendas = Source{[Schema="powerbi_lab",Item="vendas"]}[Data]
in
    Vendas

// --- IMPORTAR CSV ---
let
    Source = Csv.Document(
        File.Contents("C:\PowerBI\Data\vendas.csv"),
        [Delimiter=",", Encoding=65001, QuoteStyle=QuoteStyle.Csv]
    ),
    PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    ChangedTypes = Table.TransformColumnTypes(PromotedHeaders,{
        {"id", Int64.Type},
        {"data_venda", type date},
        {"quantidade", Int64.Type},
        {"preco_unitario", Currency.Type},
        {"valor_total", Currency.Type}
    })
in
    ChangedTypes

// --- TRANSFORMAÇÃO: ADICIONAR COLUNAS CALCULADAS ---
let
    Source = Csv.Document(File.Contents("C:\PowerBI\Data\financeiro.csv"),[Delimiter=",", Encoding=65001]),
    PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    AddMargem = Table.AddColumn(PromotedHeaders, "Classificacao", each
        if [margem_percentual] > 30 then "Alta"
        else if [margem_percentual] > 15 then "Média"
        else "Baixa"
    ),
    AddAnoMes = Table.AddColumn(AddMargem, "AnoMes", each
        Text.From([ano]) & "-" & [mes]
    )
in
    AddAnoMes

// --- MERGE DE TABELAS ---
let
    Vendas = Csv.Document(File.Contents("C:\PowerBI\Data\vendas.csv"),[Delimiter=",", Encoding=65001]),
    VendasHeaders = Table.PromoteHeaders(Vendas, [PromoteAllScalars=true]),
    Marketing = Csv.Document(File.Contents("C:\PowerBI\Data\marketing.csv"),[Delimiter=",", Encoding=65001]),
    MarketingHeaders = Table.PromoteHeaders(Marketing, [PromoteAllScalars=true]),
    Merged = Table.NestedJoin(
        VendasHeaders, {"regiao"},
        MarketingHeaders, {"regiao"},
        "Marketing", JoinKind.LeftOuter
    ),
    Expanded = Table.ExpandTableColumn(Merged, "Marketing", {"investimento", "conversoes"})
in
    Expanded

// --- PIVOT / UNPIVOT ---
let
    Source = Csv.Document(File.Contents("C:\PowerBI\Data\financeiro.csv"),[Delimiter=",", Encoding=65001]),
    PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    SelectedColumns = Table.SelectColumns(PromotedHeaders, {"regiao", "receita", "despesa", "lucro"}),
    Unpivoted = Table.Unpivot(SelectedColumns, {"receita", "despesa", "lucro"}, "Metrica", "Valor")
in
    Unpivoted
"@
    Set-Content -Path "$templatesPath\powerquery\exemplos-powerquery.m" -Value $powerQueryExamples -Encoding UTF8

    # =========================================================
    # GUIA DE DASHBOARDS
    # =========================================================
    $dashboardGuide = @"
# PowerBI Lab - Guia de Dashboards

## Dashboard 1: Vendas por Região
- **Visual**: Mapa ou gráfico de barras
- **Dados**: Vendas (CSV ou SQL Server)
- **Medidas DAX**: Total Vendas, Ticket Médio, Participação Regional
- **Filtros**: Região, Canal, Período

## Dashboard 2: Marketing ROI
- **Visual**: Gráfico de dispersão + KPI cards
- **Dados**: Marketing + Vendas (merge por região)
- **Medidas DAX**: Total Investimento, ROI Marketing, Custo por Conversão
- **Filtros**: Canal, Departamento

## Dashboard 3: Financeiro Executivo
- **Visual**: Waterfall chart + Line chart
- **Dados**: Financeiro
- **Medidas DAX**: Total Receita, Total Despesa, Lucro Líquido, Margem Média
- **Filtros**: Ano, Mês, Região

## Dashboard 4: RH Analytics
- **Visual**: Treemap + Table
- **Dados**: RH
- **Medidas DAX**: Total Funcionários, Salário Médio, Custo Folha
- **Filtros**: Departamento, Cargo, Status

## Dashboard 5: Mercado de Ações
- **Visual**: Candlestick + Line chart
- **Dados**: Acoes
- **Medidas DAX**: Preço Médio, Volume Total, Variação Média
- **Filtros**: Ticker, Período

## Dashboard 6: Logística Operacional
- **Visual**: Gauge + Map
- **Dados**: Logistica
- **Medidas**: Tempo médio entrega, Custo frete total, Taxa entrega
- **Filtros**: Transportadora, Status, Região

## Como criar no Power BI Desktop:
1. Abra Power BI Desktop
2. Obtenha Dados > SQL Server / PostgreSQL / MySQL / Texto/CSV
3. Selecione tabelas desejadas
4. Crie medidas usando exemplos em C:\PowerBI\Templates\dax\
5. Arraste campos para o canvas e configure visuais
6. Salve em C:\PowerBI\Projetos\
"@
    Set-Content -Path "$templatesPath\dashboards\guia-dashboards.md" -Value $dashboardGuide -Encoding UTF8

    # =========================================================
    # TEMPLATE PBIT (metadados JSON para referência)
    # =========================================================
    $pbitReadme = @"
# Templates Power BI (.pbit)

Os arquivos .pbit são templates binários do Power BI Desktop.
Para criar templates a partir deste laboratório:

1. Abra Power BI Desktop
2. Conecte-se ao banco PowerBILab (SQL Server: localhost\SQLEXPRESS)
3. Importe tabelas: Vendas, Marketing, Financeiro, RH, Logistica, Contabilidade, Acoes
4. Crie relacionamentos entre tabelas (quando aplicável, via coluna 'regiao')
5. Adicione medidas DAX de C:\PowerBI\Templates\dax\medidas-exemplo.dax
6. Crie visuais conforme guia em dashboards\guia-dashboards.md
7. Arquivo > Exportar > Template Power BI (.pbit)
8. Salve em C:\PowerBI\Templates\pbit\

## Templates sugeridos:
- vendas-regional.pbit
- marketing-roi.pbit
- financeiro-executivo.pbit
- rh-analytics.pbit
- acoes-mercado.pbit
- logistica-operacional.pbit
- dashboard-integrado.pbit
"@
    Set-Content -Path "$templatesPath\pbit\README.md" -Value $pbitReadme -Encoding UTF8

    Write-Log "Templates Power BI criados em $templatesPath" -Level "SUCCESS"
}
