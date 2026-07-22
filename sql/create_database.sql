-- ============================================================
-- PowerBI Lab - Script de criação do banco de dados
-- Cria database PowerBILab e todas as tabelas de datasets
-- ============================================================

USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'PowerBILab')
BEGIN
    CREATE DATABASE PowerBILab;
    PRINT 'Database PowerBILab criado.';
END
GO

USE PowerBILab;
GO

-- Tabela: Vendas
IF OBJECT_ID('dbo.Vendas', 'U') IS NOT NULL DROP TABLE dbo.Vendas;
CREATE TABLE dbo.Vendas (
    id              INT PRIMARY KEY,
    data_venda      DATE NOT NULL,
    produto         NVARCHAR(100) NOT NULL,
    regiao          NVARCHAR(50) NOT NULL,
    quantidade      INT NOT NULL,
    preco_unitario  DECIMAL(18,2) NOT NULL,
    valor_total     DECIMAL(18,2) NOT NULL,
    canal           NVARCHAR(50) NOT NULL,
    codigo_pedido   NVARCHAR(20) NOT NULL
);
GO

-- Tabela: Marketing
IF OBJECT_ID('dbo.Marketing', 'U') IS NOT NULL DROP TABLE dbo.Marketing;
CREATE TABLE dbo.Marketing (
    id              INT PRIMARY KEY,
    data_campanha   DATE NOT NULL,
    canal           NVARCHAR(50) NOT NULL,
    regiao          NVARCHAR(50) NOT NULL,
    investimento    DECIMAL(18,2) NOT NULL,
    impressoes      INT NOT NULL,
    conversoes      INT NOT NULL,
    taxa_conversao  DECIMAL(10,2) NOT NULL,
    departamento    NVARCHAR(50) NOT NULL
);
GO

-- Tabela: Financeiro
IF OBJECT_ID('dbo.Financeiro', 'U') IS NOT NULL DROP TABLE dbo.Financeiro;
CREATE TABLE dbo.Financeiro (
    id                  INT PRIMARY KEY,
    data_lancamento     DATE NOT NULL,
    regiao              NVARCHAR(50) NOT NULL,
    receita             DECIMAL(18,2) NOT NULL,
    despesa             DECIMAL(18,2) NOT NULL,
    lucro               DECIMAL(18,2) NOT NULL,
    margem_percentual   DECIMAL(10,2) NOT NULL,
    mes                 NVARCHAR(10) NOT NULL,
    ano                 INT NOT NULL
);
GO

-- Tabela: RH
IF OBJECT_ID('dbo.RH', 'U') IS NOT NULL DROP TABLE dbo.RH;
CREATE TABLE dbo.RH (
    id              INT PRIMARY KEY,
    nome            NVARCHAR(100) NOT NULL,
    cargo           NVARCHAR(50) NOT NULL,
    departamento    NVARCHAR(50) NOT NULL,
    regiao          NVARCHAR(50) NOT NULL,
    salario         DECIMAL(18,2) NOT NULL,
    data_admissao   DATE NOT NULL,
    status          NVARCHAR(20) NOT NULL,
    idade           INT NOT NULL
);
GO

-- Tabela: Logistica
IF OBJECT_ID('dbo.Logistica', 'U') IS NOT NULL DROP TABLE dbo.Logistica;
CREATE TABLE dbo.Logistica (
    id              INT PRIMARY KEY,
    data_envio      DATE NOT NULL,
    pedido          NVARCHAR(20) NOT NULL,
    transportadora  NVARCHAR(50) NOT NULL,
    origem          NVARCHAR(50) NOT NULL,
    destino         NVARCHAR(50) NOT NULL,
    peso_kg         DECIMAL(10,2) NOT NULL,
    custo_frete     DECIMAL(18,2) NOT NULL,
    dias_entrega    INT NOT NULL,
    status          NVARCHAR(20) NOT NULL
);
GO

-- Tabela: Contabilidade
IF OBJECT_ID('dbo.Contabilidade', 'U') IS NOT NULL DROP TABLE dbo.Contabilidade;
CREATE TABLE dbo.Contabilidade (
    id              INT PRIMARY KEY,
    data_lancamento DATE NOT NULL,
    conta           NVARCHAR(100) NOT NULL,
    tipo            NVARCHAR(10) NOT NULL,
    valor           DECIMAL(18,2) NOT NULL,
    regiao          NVARCHAR(50) NOT NULL,
    documento       NVARCHAR(20) NOT NULL,
    centro_custo    NVARCHAR(50) NOT NULL
);
GO

-- Tabela: Acoes
IF OBJECT_ID('dbo.Acoes', 'U') IS NOT NULL DROP TABLE dbo.Acoes;
CREATE TABLE dbo.Acoes (
    id                      INT PRIMARY KEY,
    data                    DATE NOT NULL,
    ticker                  NVARCHAR(10) NOT NULL,
    empresa                 NVARCHAR(100) NOT NULL,
    abertura                DECIMAL(18,2) NOT NULL,
    maxima                  DECIMAL(18,2) NOT NULL,
    minima                  DECIMAL(18,2) NOT NULL,
    fechamento              DECIMAL(18,2) NOT NULL,
    volume                  BIGINT NOT NULL,
    variacao_percentual     DECIMAL(10,2) NOT NULL
);
GO

PRINT 'Todas as tabelas criadas com sucesso.';
GO
