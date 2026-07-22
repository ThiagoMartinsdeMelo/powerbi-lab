-- ============================================================
-- PowerBI Lab - AdventureWorks Sample Database (simplificado)
-- Modelo dimensional para exercícios avançados de BI
-- ============================================================

USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'AdventureWorks')
BEGIN
    CREATE DATABASE AdventureWorks;
END
GO

USE AdventureWorks;
GO

-- Dimensão: Produto
IF OBJECT_ID('dbo.DimProduct', 'U') IS NOT NULL DROP TABLE dbo.DimProduct;
CREATE TABLE dbo.DimProduct (
    ProductKey      INT PRIMARY KEY,
    ProductName     NVARCHAR(100) NOT NULL,
    ProductCategory NVARCHAR(50) NOT NULL,
    Color           NVARCHAR(20),
    ListPrice       DECIMAL(18,2) NOT NULL,
    StandardCost    DECIMAL(18,2) NOT NULL
);

-- Dimensão: Cliente
IF OBJECT_ID('dbo.DimCustomer', 'U') IS NOT NULL DROP TABLE dbo.DimCustomer;
CREATE TABLE dbo.DimCustomer (
    CustomerKey  INT PRIMARY KEY,
    FirstName    NVARCHAR(50) NOT NULL,
    LastName     NVARCHAR(50) NOT NULL,
    Email        NVARCHAR(100),
    City         NVARCHAR(50),
    StateProvince NVARCHAR(50),
    Country      NVARCHAR(50)
);

-- Dimensão: Data
IF OBJECT_ID('dbo.DimDate', 'U') IS NOT NULL DROP TABLE dbo.DimDate;
CREATE TABLE dbo.DimDate (
    DateKey     INT PRIMARY KEY,
    FullDate    DATE NOT NULL,
    Year        INT NOT NULL,
    Quarter     INT NOT NULL,
    Month       INT NOT NULL,
    MonthName   NVARCHAR(20) NOT NULL,
    DayOfWeek   NVARCHAR(20) NOT NULL
);

-- Fato: Vendas
IF OBJECT_ID('dbo.FactSales', 'U') IS NOT NULL DROP TABLE dbo.FactSales;
CREATE TABLE dbo.FactSales (
    SalesKey        INT IDENTITY(1,1) PRIMARY KEY,
    ProductKey      INT REFERENCES dbo.DimProduct(ProductKey),
    CustomerKey     INT REFERENCES dbo.DimCustomer(CustomerKey),
    DateKey         INT REFERENCES dbo.DimDate(DateKey),
    OrderQuantity   INT NOT NULL,
    UnitPrice       DECIMAL(18,2) NOT NULL,
    TotalAmount     DECIMAL(18,2) NOT NULL,
    DiscountAmount  DECIMAL(18,2) DEFAULT 0
);

-- Dados de exemplo
INSERT INTO dbo.DimProduct VALUES
(1, 'Mountain Bike 100', 'Bicicletas', 'Preto', 2500.00, 1200.00),
(2, 'Road Bike 200', 'Bicicletas', 'Vermelho', 3500.00, 1800.00),
(3, 'Helmet Sport', 'Acessórios', 'Azul', 89.90, 35.00),
(4, 'Water Bottle', 'Acessórios', 'Transparente', 29.90, 8.00),
(5, 'Cycling Jersey', 'Vestuário', 'Verde', 149.90, 55.00);

INSERT INTO dbo.DimCustomer VALUES
(1, 'João', 'Silva', 'joao@email.com', 'São Paulo', 'SP', 'Brasil'),
(2, 'Maria', 'Santos', 'maria@email.com', 'Rio de Janeiro', 'RJ', 'Brasil'),
(3, 'Carlos', 'Oliveira', 'carlos@email.com', 'Belo Horizonte', 'MG', 'Brasil'),
(4, 'Ana', 'Costa', 'ana@email.com', 'Curitiba', 'PR', 'Brasil'),
(5, 'Pedro', 'Lima', 'pedro@email.com', 'Porto Alegre', 'RS', 'Brasil');

INSERT INTO dbo.DimDate VALUES
(20240101, '2024-01-01', 2024, 1, 1, 'Janeiro', 'Segunda'),
(20240115, '2024-01-15', 2024, 1, 1, 'Janeiro', 'Segunda'),
(20240201, '2024-02-01', 2024, 1, 2, 'Fevereiro', 'Quinta'),
(20240301, '2024-03-01', 2024, 1, 3, 'Março', 'Sexta'),
(20240401, '2024-04-01', 2024, 2, 4, 'Abril', 'Segunda');

INSERT INTO dbo.FactSales (ProductKey, CustomerKey, DateKey, OrderQuantity, UnitPrice, TotalAmount, DiscountAmount) VALUES
(1, 1, 20240101, 1, 2500.00, 2500.00, 0),
(3, 1, 20240101, 2, 89.90, 179.80, 0),
(2, 2, 20240115, 1, 3500.00, 3500.00, 175.00),
(4, 3, 20240201, 5, 29.90, 149.50, 0),
(5, 4, 20240301, 3, 149.90, 449.70, 22.49),
(1, 5, 20240401, 2, 2500.00, 5000.00, 250.00);

PRINT 'AdventureWorks sample database criado.';
GO
