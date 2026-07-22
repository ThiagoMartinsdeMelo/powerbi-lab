#Requires -RunAsAdministrator
#Requires -Version 5.1
<#
.SYNOPSIS
    Cria notebooks Jupyter de Machine Learning integrados com Power BI.
#>

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\common-functions.ps1"

function New-JupyterNotebook {
    param(
        [string]$FilePath,
        [string]$Title,
        [array]$Cells
    )

    $notebook = @{
        cells = $Cells
        metadata = @{
            kernelspec = @{
                display_name = "PowerBI Lab (Python 3.11)"
                language = "python"
                name = "powerbi-lab"
            }
            language_info = @{
                name = "python"
                version = "3.11.0"
            }
        }
        nbformat = 4
        nbformat_minor = 5
    }

    $notebook | ConvertTo-Json -Depth 10 | Set-Content -Path $FilePath -Encoding UTF8
}

Invoke-SafeExecution -Description "Setup notebooks Jupyter" -ScriptBlock {
    $notebooksPath = "C:\PowerBI\MachineLearning\notebooks"

    # =========================================================
    # 1. REGRESSÃO LINEAR
    # =========================================================
    $cellsRegressao = @(
        @{ cell_type = "markdown"; metadata = @{}; source = @("# Regressão Linear - Previsão de Vendas`n`nEste notebook demonstra regressão linear para prever vendas com base em investimento de marketing.`n`n**Integração Power BI**: Exporte predições para CSV e importe no Power BI.") }
        @{ cell_type = "code"; metadata = @{}; execution_count = $null; outputs = @(); source = @("import pandas as pd`nimport numpy as np`nimport matplotlib.pyplot as plt`nimport seaborn as sns`nfrom sklearn.linear_model import LinearRegression`nfrom sklearn.model_selection import train_test_split`nfrom sklearn.metrics import r2_score, mean_squared_error`n`nDATA_PATH = r'C:\PowerBI\Data'`nEXPORT_PATH = r'C:\PowerBI\Exports'`n`nsns.set_style('whitegrid')`nplt.rcParams['figure.figsize'] = (12, 6)") }
        @{ cell_type = "code"; metadata = @{}; execution_count = $null; outputs = @(); source = @("# Carregar dados`nmarketing = pd.read_csv(f'{DATA_PATH}/marketing.csv')`nvendas = pd.read_csv(f'{DATA_PATH}/vendas.csv')`n`n# Agregar por região`nmk_agg = marketing.groupby('regiao').agg(investimento_total=('investimento', 'sum')).reset_index()`nvendas_agg = vendas.groupby('regiao').agg(vendas_total=('valor_total', 'sum')).reset_index()`n`ndf = pd.merge(mk_agg, vendas_agg, on='regiao')`ndf.head()") }
        @{ cell_type = "code"; metadata = @{}; execution_count = $null; outputs = @(); source = @("# Treinar modelo de Regressão Linear`nX = df[['investimento_total']]`ny = df['vendas_total']`n`nX_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)`n`nmodel = LinearRegression()`nmodel.fit(X_train, y_train)`n`ny_pred = model.predict(X_test)`nprint(f'R² Score: {r2_score(y_test, y_pred):.4f}')`nprint(f'RMSE: {np.sqrt(mean_squared_error(y_test, y_pred)):,.2f}')`nprint(f'Coeficiente: {model.coef_[0]:.4f}')`nprint(f'Intercepto: {model.intercept_:,.2f}')") }
        @{ cell_type = "code"; metadata = @{}; execution_count = $null; outputs = @(); source = @("# Visualização`nplt.scatter(X_test, y_test, color='blue', label='Real', alpha=0.6)`nplt.plot(X_test, y_pred, color='red', linewidth=2, label='Predição')`nplt.xlabel('Investimento Marketing')`nplt.ylabel('Vendas Totais')`nplt.title('Regressão Linear: Marketing vs Vendas')`nplt.legend()`nplt.savefig(f'{EXPORT_PATH}/regressao_linear.png', dpi=150, bbox_inches='tight')`nplt.show()") }
        @{ cell_type = "code"; metadata = @{}; execution_count = $null; outputs = @(); source = @("# Exportar predições para Power BI`npredictions = pd.DataFrame({'regiao': df['regiao'], 'vendas_real': df['vendas_total'], 'vendas_predita': model.predict(df[['investimento_total']])})`npredictions.to_csv(f'{EXPORT_PATH}/predicoes_regressao.csv', index=False)`nprint('Predições exportadas para Power BI!')") }
    )
    New-JupyterNotebook -FilePath "$notebooksPath\01_regressao_linear.ipynb" -Title "Regressão Linear" -Cells $cellsRegressao

    # =========================================================
    # 2. CLASSIFICAÇÃO
    # =========================================================
    $cellsClassificacao = @(
        @{ cell_type = "markdown"; metadata = @{}; source = @("# Classificação - Previsão de Status de Entrega`n`nClassifica entregas como 'Entregue' ou 'Atrasada' com base em features logísticas.") }
        @{ cell_type = "code"; metadata = @{}; execution_count = $null; outputs = @(); source = @("import pandas as pd`nimport numpy as np`nfrom sklearn.ensemble import RandomForestClassifier`nfrom sklearn.model_selection import train_test_split`nfrom sklearn.metrics import classification_report, confusion_matrix`nimport seaborn as sns`nimport matplotlib.pyplot as plt`n`nDATA_PATH = r'C:\PowerBI\Data'`nEXPORT_PATH = r'C:\PowerBI\Exports'") }
        @{ cell_type = "code"; metadata = @{}; execution_count = $null; outputs = @(); source = @("df = pd.read_csv(f'{DATA_PATH}/logistica.csv')`ndf['atrasada'] = (df['dias_entrega'] > 7).astype(int)`n`nfeatures = ['peso_kg', 'custo_frete', 'dias_entrega']`nX = df[features]`ny = df['atrasada']`n`nX_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)`n`nclf = RandomForestClassifier(n_estimators=100, random_state=42)`nclf.fit(X_train, y_train)`n`ny_pred = clf.predict(X_test)`nprint(classification_report(y_test, y_pred, target_names=['No Prazo', 'Atrasada']))") }
        @{ cell_type = "code"; metadata = @{}; execution_count = $null; outputs = @(); source = @("# Matriz de confusão`ncm = confusion_matrix(y_test, y_pred)`nsns.heatmap(cm, annot=True, fmt='d', cmap='Blues', xticklabels=['No Prazo', 'Atrasada'], yticklabels=['No Prazo', 'Atrasada'])`nplt.title('Matriz de Confusão - Classificação de Entregas')`nplt.savefig(f'{EXPORT_PATH}/classificacao_confusion_matrix.png', dpi=150)`nplt.show()") }
        @{ cell_type = "code"; metadata = @{}; execution_count = $null; outputs = @(); source = @("# Exportar resultados`nresults = pd.DataFrame({'real': y_test.values, 'predito': y_pred, 'probabilidade_atraso': clf.predict_proba(X_test)[:, 1]})`nresults.to_csv(f'{EXPORT_PATH}/classificacao_resultados.csv', index=False)`nprint('Resultados exportados!')") }
    )
    New-JupyterNotebook -FilePath "$notebooksPath\02_classificacao.ipynb" -Title "Classificação" -Cells $cellsClassificacao

    # =========================================================
    # 3. CLUSTERIZAÇÃO
    # =========================================================
    $cellsCluster = @(
        @{ cell_type = "markdown"; metadata = @{}; source = @("# Clusterização - Segmentação de Clientes por Região`n`nAgrupa regiões com perfis similares de vendas e marketing usando K-Means.") }
        @{ cell_type = "code"; metadata = @{}; execution_count = $null; outputs = @(); source = @("import pandas as pd`nimport numpy as np`nfrom sklearn.cluster import KMeans`nfrom sklearn.preprocessing import StandardScaler`nimport matplotlib.pyplot as plt`n`nDATA_PATH = r'C:\PowerBI\Data'`nEXPORT_PATH = r'C:\PowerBI\Exports'") }
        @{ cell_type = "code"; metadata = @{}; execution_count = $null; outputs = @(); source = @("vendas = pd.read_csv(f'{DATA_PATH}/vendas.csv')`nmarketing = pd.read_csv(f'{DATA_PATH}/marketing.csv')`n`nv_agg = vendas.groupby('regiao').agg(vendas_total=('valor_total', 'sum'), qtd_pedidos=('codigo_pedido', 'nunique')).reset_index()`nm_agg = marketing.groupby('regiao').agg(investimento=('investimento', 'sum'), conversoes=('conversoes', 'sum')).reset_index()`n`ndf = pd.merge(v_agg, m_agg, on='regiao')`n`nscaler = StandardScaler()`nX_scaled = scaler.fit_transform(df[['vendas_total', 'investimento', 'conversoes']])`n`nkmeans = KMeans(n_clusters=3, random_state=42, n_init=10)`ndf['cluster'] = kmeans.fit_predict(X_scaled)`ndf") }
        @{ cell_type = "code"; metadata = @{}; execution_count = $null; outputs = @(); source = @("plt.scatter(df['vendas_total'], df['investimento'], c=df['cluster'], cmap='viridis', s=100)`nfor i, row in df.iterrows():`n    plt.annotate(row['regiao'], (row['vendas_total'], row['investimento']))`nplt.xlabel('Vendas Total')`nplt.ylabel('Investimento Marketing')`nplt.title('Clusterização de Regiões')`nplt.savefig(f'{EXPORT_PATH}/clusterizacao.png', dpi=150)`nplt.show()") }
        @{ cell_type = "code"; metadata = @{}; execution_count = $null; outputs = @(); source = @("df.to_csv(f'{EXPORT_PATH}/clusters_regioes.csv', index=False)`nprint('Clusters exportados para Power BI!')") }
    )
    New-JupyterNotebook -FilePath "$notebooksPath\03_clusterizacao.ipynb" -Title "Clusterização" -Cells $cellsCluster

    # =========================================================
    # 4. DETECÇÃO DE ANOMALIAS
    # =========================================================
    $cellsAnomalias = @(
        @{ cell_type = "markdown"; metadata = @{}; source = @("# Detecção de Anomalias - Transações Financeiras`n`nIdentifica lançamentos contábeis atípicos usando Isolation Forest.") }
        @{ cell_type = "code"; metadata = @{}; execution_count = $null; outputs = @(); source = @("import pandas as pd`nimport numpy as np`nfrom sklearn.ensemble import IsolationForest`nimport matplotlib.pyplot as plt`n`nDATA_PATH = r'C:\PowerBI\Data'`nEXPORT_PATH = r'C:\PowerBI\Exports'") }
        @{ cell_type = "code"; metadata = @{}; execution_count = $null; outputs = @(); source = @("df = pd.read_csv(f'{DATA_PATH}/contabilidade.csv')`ndf['data_lancamento'] = pd.to_datetime(df['data_lancamento'])`n`niso_forest = IsolationForest(contamination=0.05, random_state=42)`ndf['anomalia'] = iso_forest.fit_predict(df[['valor']])`ndf['anomalia_label'] = df['anomalia'].map({1: 'Normal', -1: 'Anomalia'})`n`nanomalias = df[df['anomalia'] == -1]`nprint(f'Total de anomalias detectadas: {len(anomalias)}')`nanomalias.head(10)") }
        @{ cell_type = "code"; metadata = @{}; execution_count = $null; outputs = @(); source = @("plt.figure(figsize=(14, 6))`nnormal = df[df['anomalia'] == 1]`nanomalos = df[df['anomalia'] == -1]`nplt.scatter(normal.index, normal['valor'], c='blue', alpha=0.3, label='Normal', s=10)`nplt.scatter(anomalos.index, anomalos['valor'], c='red', label='Anomalia', s=30)`nplt.xlabel('Índice')`nplt.ylabel('Valor')`nplt.title('Detecção de Anomalias - Contabilidade')`nplt.legend()`nplt.savefig(f'{EXPORT_PATH}/anomalias_contabilidade.png', dpi=150)`nplt.show()") }
        @{ cell_type = "code"; metadata = @{}; execution_count = $null; outputs = @(); source = @("df.to_csv(f'{EXPORT_PATH}/anomalias_contabilidade.csv', index=False)`nprint('Anomalias exportadas!')") }
    )
    New-JupyterNotebook -FilePath "$notebooksPath\04_deteccao_anomalias.ipynb" -Title "Detecção de Anomalias" -Cells $cellsAnomalias

    # =========================================================
    # 5. SÉRIES TEMPORAIS
    # =========================================================
    $cellsSeries = @(
        @{ cell_type = "markdown"; metadata = @{}; source = @("# Séries Temporais - Previsão de Vendas`n`nPrevisão de vendas futuras usando decomposição temporal e média móvel.`n`n**Integração Power BI**: Importe previsões como tabela de datas.") }
        @{ cell_type = "code"; metadata = @{}; execution_count = $null; outputs = @(); source = @("import pandas as pd`nimport numpy as np`nimport matplotlib.pyplot as plt`nfrom statsmodels.tsa.seasonal import seasonal_decompose`n`nDATA_PATH = r'C:\PowerBI\Data'`nEXPORT_PATH = r'C:\PowerBI\Exports'") }
        @{ cell_type = "code"; metadata = @{}; execution_count = $null; outputs = @(); source = @("df = pd.read_csv(f'{DATA_PATH}/vendas.csv')`ndf['data_venda'] = pd.to_datetime(df['data_venda'])`n`nts = df.groupby('data_venda')['valor_total'].sum().reset_index()`nts = ts.set_index('data_venda').sort_index()`nts_daily = ts.resample('M').sum()`nts_daily.columns = ['vendas']`nts_daily.head()") }
        @{ cell_type = "code"; metadata = @{}; execution_count = $null; outputs = @(); source = @("# Decomposição sazonal`ndecomposition = seasonal_decompose(ts_daily['vendas'], model='additive', period=12)`nfig = decomposition.plot()`nfig.set_size_inches(14, 10)`nplt.savefig(f'{EXPORT_PATH}/series_temporais_decomposicao.png', dpi=150)`nplt.show()") }
        @{ cell_type = "code"; metadata = @{}; execution_count = $null; outputs = @(); source = @("# Previsão com média móvel`nts_daily['media_movel_3m'] = ts_daily['vendas'].rolling(window=3).mean()`nts_daily['media_movel_6m'] = ts_daily['vendas'].rolling(window=6).mean()`n`nplt.figure(figsize=(14, 6))`nplt.plot(ts_daily.index, ts_daily['vendas'], label='Vendas Reais', alpha=0.7)`nplt.plot(ts_daily.index, ts_daily['media_movel_3m'], label='MM 3 meses', linewidth=2)`nplt.plot(ts_daily.index, ts_daily['media_movel_6m'], label='MM 6 meses', linewidth=2)`nplt.title('Série Temporal - Vendas Mensais')`nplt.legend()`nplt.savefig(f'{EXPORT_PATH}/series_temporais_previsao.png', dpi=150)`nplt.show()") }
        @{ cell_type = "code"; metadata = @{}; execution_count = $null; outputs = @(); source = @("ts_daily.reset_index().to_csv(f'{EXPORT_PATH}/series_temporais_vendas.csv', index=False)`nprint('Série temporal exportada para Power BI!')") }
    )
    New-JupyterNotebook -FilePath "$notebooksPath\05_series_temporais.ipynb" -Title "Séries Temporais" -Cells $cellsSeries

    Write-Log "5 notebooks Jupyter criados em $notebooksPath" -Level "SUCCESS"
}
