#Requires -RunAsAdministrator
#Requires -Version 5.1
<#
.SYNOPSIS
    Instala Python 3, PowerShell 7 e pacotes de Data Science/ML.
.DESCRIPTION
    Cria ambiente virtual em C:\PowerBI\MachineLearning\venv com pandas,
    numpy, scikit-learn, tensorflow, jupyter e conectores de banco.
#>

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\common-functions.ps1"

Invoke-SafeExecution -Description "Instalação Python e ambiente ML" -ScriptBlock {
    # PowerShell 7
    Install-ChocoPackage -PackageName "powershell-core"

    # Python 3
    Install-ChocoPackage -PackageName "python" -ExtraArgs @("--version", "3.11.9")

    # Utilitários
    Install-ChocoPackage -PackageName "7zip"
    Install-ChocoPackage -PackageName "notepadplusplus"

    Refresh-EnvironmentPath

    $pythonPath = (Get-Command python -ErrorAction SilentlyContinue).Source
    if (-not $pythonPath) {
        $pythonPath = "${env:ProgramFiles}\Python311\python.exe"
    }

    if (-not (Test-Path $pythonPath)) {
        throw "Python não encontrado após instalação."
    }

    Write-Log "Python encontrado em: $pythonPath" -Level "INFO"

    # Criar ambiente virtual
    $venvPath = "C:\PowerBI\MachineLearning\venv"
    if (-not (Test-Path "$venvPath\Scripts\python.exe")) {
        & $pythonPath -m venv $venvPath
        Write-Log "Ambiente virtual criado em: $venvPath" -Level "SUCCESS"
    }

    $venvPython = "$venvPath\Scripts\python.exe"
    $venvPip = "$venvPath\Scripts\pip.exe"

    # Atualizar pip
    & $venvPython -m pip install --upgrade pip wheel setuptools

    # Pacotes de Data Science e ML
    $packages = @(
        "pandas", "numpy", "matplotlib", "seaborn", "plotly",
        "scikit-learn", "tensorflow", "jupyter", "notebook",
        "openpyxl", "sqlalchemy", "pyodbc", "psycopg2-binary",
        "mysql-connector-python", "ipykernel", "jupyterlab", "statsmodels"
    )

    foreach ($pkg in $packages) {
        Write-Log "Instalando pacote Python: $pkg" -Level "INFO"
        & $venvPip install $pkg --quiet
    }

    # Registrar kernel Jupyter
    & $venvPython -m ipykernel install --user --name powerbi-lab --display-name "PowerBI Lab (Python 3.11)"

    # Atalho Jupyter Notebook
    $jupyterScript = @"
@echo off
call C:\PowerBI\MachineLearning\venv\Scripts\activate.bat
cd /d C:\PowerBI\MachineLearning\notebooks
jupyter notebook --notebook-dir=C:\PowerBI\MachineLearning\notebooks
"@
    Set-Content -Path "C:\PowerBI\MachineLearning\start-jupyter.bat" -Value $jupyterScript

    Write-Log "Ambiente Python/ML configurado com sucesso." -Level "SUCCESS"
}
