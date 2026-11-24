/* =========================================================
   Laboratorio CRUD ASP.NET - Base de datos InventarioDB
   Motor: Microsoft SQL Server (ejecutar en SQL Server Management Studio)
   Para MySQL use el archivo InventarioDB_MySQL.sql
   Instrucciones: abrir este archivo en SSMS y presionar F5 (Ejecutar).

   Codificacion de productos (norma de calidad):
   cada producto recibe automaticamente un codigo PREFIJO-NNN segun su
   categoria (ej. ELE-003). El consecutivo de cada categoria nunca se
   reutiliza, aunque se elimine un producto.
   ========================================================= */

USE master;
GO

IF DB_ID('InventarioDB') IS NOT NULL
BEGIN
    ALTER DATABASE InventarioDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE InventarioDB;
END
GO

CREATE DATABASE InventarioDB;
GO

USE InventarioDB;
GO

/* ---------------- TABLAS ---------------- */
CREATE TABLE Categorias (
    CategoriaId INT IDENTITY(1,1) PRIMARY KEY,
    Nombre      NVARCHAR(50) NOT NULL UNIQUE,
    Prefijo     CHAR(3)      NOT NULL UNIQUE,   -- prefijo del codigo de producto
    Consecutivo INT          NOT NULL DEFAULT 0  -- ultimo numero asignado
);
GO

CREATE TABLE Productos (
    ProductoId   INT IDENTITY(1,1) PRIMARY KEY,
    Codigo       NVARCHAR(20)  NOT NULL UNIQUE,
    Nombre       NVARCHAR(100) NOT NULL,
    Descripcion  NVARCHAR(250) NULL,
    CategoriaId  INT           NOT NULL,
    Precio       DECIMAL(10,2) NOT NULL CHECK (Precio >= 0),
    Stock        INT           NOT NULL CHECK (Stock >= 0),
    FechaIngreso DATE          NOT NULL DEFAULT (CAST(GETDATE() AS DATE)),
    CONSTRAINT FK_Productos_Categorias FOREIGN KEY (CategoriaId)
        REFERENCES Categorias (CategoriaId)
);
GO

/* ---------------- DATOS DE PRUEBA ---------------- */
INSERT INTO Categorias (Nombre, Prefijo, Consecutivo) VALUES
('Electronica',  'ELE', 2),
('Oficina',      'OFI', 2),
('Limpieza',     'LIM', 1),
('Alimentos',    'ALI', 1),
('Herramientas', 'HER', 1);
GO

INSERT INTO Productos (Codigo, Nombre, Descripcion, CategoriaId, Precio, Stock, FechaIngreso) VALUES
('ELE-001', 'Mouse inalambrico',  'Mouse optico 2.4 GHz',          1,  15.99, 40,  '2026-10-01'),
('ELE-002', 'Teclado USB',        'Teclado en espanol, USB',       1,  22.50, 25,  '2026-10-05'),
('OFI-001', 'Resma de papel',     'Papel bond 8.5x11, 500 hojas',  2,   5.75, 120, '2026-10-10'),
('OFI-002', 'Boligrafos azules',  'Caja de 12 unidades',           2,   3.20, 80,  '2026-10-12'),
('LIM-001', 'Desinfectante 1L',   'Aroma lavanda',                 3,   4.10, 60,  '2026-10-15'),
('ALI-001', 'Cafe molido 500g',   'Cafe de Boquete',               4,   8.90, 35,  '2026-11-01'),
('HER-001', 'Destornillador set', 'Set de 6 piezas',               5,  12.00, 15,  '2026-11-03');
GO

/* ---------------- PROCEDIMIENTOS ALMACENADOS ---------------- */

-- Genera el siguiente codigo de una categoria (PREFIJO-NNN) y aumenta su consecutivo
CREATE PROCEDURE sp_generar_codigo
    @p_CategoriaId INT,
    @p_Codigo      NVARCHAR(20) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @numero INT, @prefijo CHAR(3);

    UPDATE Categorias
       SET @numero = Consecutivo = Consecutivo + 1,
           @prefijo = Prefijo
     WHERE CategoriaId = @p_CategoriaId;

    IF @numero IS NULL
        THROW 50001, 'La categoria no existe.', 1;

    SET @p_Codigo = @prefijo + '-' +
        CASE WHEN @numero < 1000 THEN RIGHT('000' + CAST(@numero AS VARCHAR(10)), 3)
             ELSE CAST(@numero AS VARCHAR(10)) END;
END
GO

-- READ: lista de categorias (para el DropDownList)
CREATE PROCEDURE sp_read_categorias
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CategoriaId, Nombre, Prefijo,
           Nombre + ' (' + Prefijo + ')' AS Texto
    FROM Categorias
    ORDER BY Nombre;
END
GO

-- CREATE: el codigo se genera automaticamente segun la categoria
CREATE PROCEDURE sp_create_producto
    @p_Nombre       NVARCHAR(100),
    @p_Descripcion  NVARCHAR(250),
    @p_CategoriaId  INT,
    @p_Precio       DECIMAL(10,2),
    @p_Stock        INT,
    @p_FechaIngreso DATE
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @codigo NVARCHAR(20);

    BEGIN TRANSACTION;
        EXEC sp_generar_codigo @p_CategoriaId, @codigo OUTPUT;

        INSERT INTO Productos (Codigo, Nombre, Descripcion, CategoriaId, Precio, Stock, FechaIngreso)
        VALUES (@codigo, @p_Nombre, @p_Descripcion, @p_CategoriaId, @p_Precio, @p_Stock, @p_FechaIngreso);

        SELECT CAST(SCOPE_IDENTITY() AS INT) AS ProductoId, @codigo AS Codigo;
    COMMIT TRANSACTION;
END
GO

-- READ: todos los productos, con busqueda opcional por codigo, nombre o categoria
CREATE PROCEDURE sp_read_productos
    @p_Buscar NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT p.ProductoId, p.Codigo, p.Nombre, p.Descripcion,
           p.CategoriaId, c.Nombre AS Categoria,
           p.Precio, p.Stock, p.FechaIngreso,
           CAST(p.Precio * p.Stock AS DECIMAL(12,2)) AS ValorTotal
    FROM Productos p
    INNER JOIN Categorias c ON c.CategoriaId = p.CategoriaId
    WHERE @p_Buscar IS NULL OR @p_Buscar = ''
       OR p.Codigo LIKE '%' + @p_Buscar + '%'
       OR p.Nombre LIKE '%' + @p_Buscar + '%'
       OR c.Nombre LIKE '%' + @p_Buscar + '%'
    ORDER BY p.Codigo;
END
GO

-- READ: un producto por Id (para cargar el formulario al editar)
CREATE PROCEDURE sp_read_producto_id
    @p_ProductoId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ProductoId, Codigo, Nombre, Descripcion, CategoriaId, Precio, Stock, FechaIngreso
    FROM Productos
    WHERE ProductoId = @p_ProductoId;
END
GO

-- READ: resumen para la pagina de inicio
CREATE PROCEDURE sp_resumen_inventario
AS
BEGIN
    SET NOCOUNT ON;
    SELECT COUNT(*)                                   AS TotalProductos,
           ISNULL(SUM(Stock), 0)                      AS TotalUnidades,
           ISNULL(SUM(CAST(Precio * Stock AS DECIMAL(14,2))), 0) AS ValorInventario,
           (SELECT COUNT(*) FROM Categorias)          AS TotalCategorias
    FROM Productos;
END
GO

-- UPDATE: si cambia la categoria, el producto recibe un codigo nuevo de esa categoria
CREATE PROCEDURE sp_update_producto
    @p_ProductoId   INT,
    @p_Nombre       NVARCHAR(100),
    @p_Descripcion  NVARCHAR(250),
    @p_CategoriaId  INT,
    @p_Precio       DECIMAL(10,2),
    @p_Stock        INT,
    @p_FechaIngreso DATE
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @categoriaActual INT, @codigo NVARCHAR(20);

    BEGIN TRANSACTION;
        SELECT @categoriaActual = CategoriaId, @codigo = Codigo
        FROM Productos WITH (UPDLOCK)
        WHERE ProductoId = @p_ProductoId;

        IF @categoriaActual IS NULL
        BEGIN
            COMMIT TRANSACTION;
            SELECT 0 AS FilasAfectadas, CAST(NULL AS NVARCHAR(20)) AS Codigo;
            RETURN;
        END

        IF @categoriaActual <> @p_CategoriaId
            EXEC sp_generar_codigo @p_CategoriaId, @codigo OUTPUT;

        UPDATE Productos
           SET Codigo       = @codigo,
               Nombre       = @p_Nombre,
               Descripcion  = @p_Descripcion,
               CategoriaId  = @p_CategoriaId,
               Precio       = @p_Precio,
               Stock        = @p_Stock,
               FechaIngreso = @p_FechaIngreso
         WHERE ProductoId = @p_ProductoId;

        SELECT 1 AS FilasAfectadas, @codigo AS Codigo;
    COMMIT TRANSACTION;
END
GO

-- DELETE
CREATE PROCEDURE sp_delete_producto
    @p_ProductoId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM Productos WHERE ProductoId = @p_ProductoId;

    SELECT @@ROWCOUNT AS FilasAfectadas;
END
GO

/* Prueba rapida */
EXEC sp_read_productos;
GO
