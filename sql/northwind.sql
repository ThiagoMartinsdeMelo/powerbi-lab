-- ============================================================
-- PowerBI Lab - Northwind Sample Database (simplificado)
-- Base de referência clássica para exercícios de BI
-- ============================================================

USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'Northwind')
BEGIN
    CREATE DATABASE Northwind;
END
GO

USE Northwind;
GO

IF OBJECT_ID('dbo.Categories', 'U') IS NOT NULL DROP TABLE dbo.Categories;
CREATE TABLE dbo.Categories (
    CategoryID   INT PRIMARY KEY,
    CategoryName NVARCHAR(50) NOT NULL,
    Description  NVARCHAR(200)
);

IF OBJECT_ID('dbo.Products', 'U') IS NOT NULL DROP TABLE dbo.Products;
CREATE TABLE dbo.Products (
    ProductID    INT PRIMARY KEY,
    ProductName  NVARCHAR(100) NOT NULL,
    CategoryID   INT REFERENCES dbo.Categories(CategoryID),
    UnitPrice    DECIMAL(18,2) NOT NULL,
    UnitsInStock INT NOT NULL
);

IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL DROP TABLE dbo.Customers;
CREATE TABLE dbo.Customers (
    CustomerID   NVARCHAR(10) PRIMARY KEY,
    CompanyName  NVARCHAR(100) NOT NULL,
    ContactName  NVARCHAR(50),
    Country      NVARCHAR(50)
);

IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;
CREATE TABLE dbo.Orders (
    OrderID     INT PRIMARY KEY,
    CustomerID  NVARCHAR(10) REFERENCES dbo.Customers(CustomerID),
    OrderDate   DATE NOT NULL,
    ShipCountry NVARCHAR(50)
);

IF OBJECT_ID('dbo.OrderDetails', 'U') IS NOT NULL DROP TABLE dbo.OrderDetails;
CREATE TABLE dbo.OrderDetails (
    OrderID   INT REFERENCES dbo.Orders(OrderID),
    ProductID INT REFERENCES dbo.Products(ProductID),
    UnitPrice DECIMAL(18,2) NOT NULL,
    Quantity  INT NOT NULL,
    Discount  DECIMAL(5,2) DEFAULT 0,
    PRIMARY KEY (OrderID, ProductID)
);

-- Dados de exemplo
INSERT INTO dbo.Categories VALUES
(1, 'Bebidas', 'Refrigerantes, sucos, chás'),
(2, 'Condimentos', 'Especiarias e molhos'),
(3, 'Doces', 'Chocolates e balas'),
(4, 'Laticínios', 'Queijos e iogurtes'),
(5, 'Grãos', 'Arroz, feijão, lentilha');

INSERT INTO dbo.Products VALUES
(1, 'Coca-Cola 2L', 1, 8.99, 150),
(2, 'Suco de Laranja 1L', 1, 6.50, 200),
(3, 'Ketchup Heinz', 2, 12.90, 80),
(4, 'Mostarda Dijon', 2, 9.50, 60),
(5, 'Chocolate Lindt', 3, 24.90, 45),
(6, 'Balas Fini', 3, 4.99, 300),
(7, 'Queijo Gouda', 4, 45.00, 30),
(8, 'Iogurte Natural', 4, 3.50, 120),
(9, 'Arroz Integral 1kg', 5, 8.90, 250),
(10, 'Feijão Preto 1kg', 5, 7.50, 180);

INSERT INTO dbo.Customers VALUES
('ALFKI', 'Alfreds Futterkiste', 'Maria Anders', 'Alemanha'),
('ANATR', 'Ana Trujillo', 'Ana Trujillo', 'México'),
('ANTON', 'Antonio Moreno', 'Antonio Moreno', 'México'),
('BERGS', 'Berglunds snabbköp', 'Christina Berglund', 'Suécia'),
('BLAUS', 'Blauer See Delikatessen', 'Hanna Moos', 'Alemanha');

INSERT INTO dbo.Orders VALUES
(10248, 'ALFKI', '2024-01-15', 'Alemanha'),
(10249, 'ANATR', '2024-01-16', 'México'),
(10250, 'ANTON', '2024-01-17', 'México'),
(10251, 'BERGS', '2024-01-18', 'Suécia'),
(10252, 'BLAUS', '2024-01-19', 'Alemanha');

INSERT INTO dbo.OrderDetails VALUES
(10248, 1, 8.99, 12, 0.05),
(10248, 5, 24.90, 3, 0.00),
(10249, 2, 6.50, 20, 0.10),
(10250, 3, 12.90, 5, 0.00),
(10251, 7, 45.00, 2, 0.15),
(10252, 9, 8.90, 50, 0.05);

PRINT 'Northwind sample database criado.';
GO
