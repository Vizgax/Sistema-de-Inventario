/* =========================================================
   Laboratorio CRUD ASP.NET - Base de datos InventarioDB
   Motor: MySQL 8 o superior (ejecutar en MySQL Workbench)
   Instrucciones: abrir este archivo en Workbench y ejecutar todo
   con el boton del rayo (Execute) o Ctrl+Shift+Enter.

   Codificacion de productos (norma de calidad):
   cada producto recibe automaticamente un codigo PREFIJO-NNN segun su
   categoria (ej. ELE-003). El consecutivo de cada categoria nunca se
   reutiliza, aunque se elimine un producto.
   ========================================================= */

DROP DATABASE IF EXISTS InventarioDB;
CREATE DATABASE InventarioDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE InventarioDB;

/* ---------------- TABLAS ---------------- */
CREATE TABLE Categorias (
    CategoriaId INT AUTO_INCREMENT PRIMARY KEY,
    Nombre      VARCHAR(50) NOT NULL UNIQUE,
    Prefijo     CHAR(3)     NOT NULL UNIQUE,    -- prefijo del codigo de producto
    Consecutivo INT         NOT NULL DEFAULT 0  -- ultimo numero asignado
);

CREATE TABLE Productos (
    ProductoId   INT AUTO_INCREMENT PRIMARY KEY,
    Codigo       VARCHAR(20)   NOT NULL UNIQUE,
    Nombre       VARCHAR(100)  NOT NULL,
    Descripcion  VARCHAR(250)  NULL,
    CategoriaId  INT           NOT NULL,
    Precio       DECIMAL(10,2) NOT NULL CHECK (Precio >= 0),
    Stock        INT           NOT NULL CHECK (Stock >= 0),
    FechaIngreso DATE          NOT NULL,
    CONSTRAINT FK_Productos_Categorias FOREIGN KEY (CategoriaId)
        REFERENCES Categorias (CategoriaId)
);

/* ---------------- DATOS DE PRUEBA ---------------- */
INSERT INTO Categorias (Nombre, Prefijo, Consecutivo) VALUES
('Electronica',  'ELE', 2),
('Oficina',      'OFI', 2),
('Limpieza',     'LIM', 1),
('Alimentos',    'ALI', 1),
('Herramientas', 'HER', 1);

INSERT INTO Productos (Codigo, Nombre, Descripcion, CategoriaId, Precio, Stock, FechaIngreso) VALUES
('ELE-001', 'Mouse inalambrico',  'Mouse optico 2.4 GHz',          1,  15.99, 40,  '2026-10-01'),
('ELE-002', 'Teclado USB',        'Teclado en espanol, USB',       1,  22.50, 25,  '2026-10-05'),
('OFI-001', 'Resma de papel',     'Papel bond 8.5x11, 500 hojas',  2,   5.75, 120, '2026-10-10'),
('OFI-002', 'Boligrafos azules',  'Caja de 12 unidades',           2,   3.20, 80,  '2026-10-12'),
('LIM-001', 'Desinfectante 1L',   'Aroma lavanda',                 3,   4.10, 60,  '2026-10-15'),
('ALI-001', 'Cafe molido 500g',   'Cafe de Boquete',               4,   8.90, 35,  '2026-11-01'),
('HER-001', 'Destornillador set', 'Set de 6 piezas',               5,  12.00, 15,  '2026-11-03');

/* ---------------- PROCEDIMIENTOS ALMACENADOS ---------------- */
DELIMITER $$

-- Genera el siguiente codigo de una categoria (PREFIJO-NNN) y aumenta su consecutivo
CREATE PROCEDURE sp_generar_codigo(IN p_CategoriaId INT, OUT p_Codigo VARCHAR(20))
BEGIN
    DECLARE v_numero INT DEFAULT NULL;
    DECLARE v_prefijo CHAR(3) DEFAULT NULL;

    SELECT Consecutivo + 1, Prefijo INTO v_numero, v_prefijo
    FROM Categorias
    WHERE CategoriaId = p_CategoriaId
    FOR UPDATE;

    IF v_numero IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La categoria no existe.';
    END IF;

    UPDATE Categorias SET Consecutivo = v_numero WHERE CategoriaId = p_CategoriaId;

    SET p_Codigo = CONCAT(v_prefijo, '-',
        IF(v_numero < 1000, LPAD(v_numero, 3, '0'), CAST(v_numero AS CHAR)));
END$$

-- READ: categorias (para el DropDownList)
CREATE PROCEDURE sp_read_categorias()
BEGIN
    SELECT CategoriaId, Nombre, Prefijo,
           CONCAT(Nombre, ' (', Prefijo, ')') AS Texto
    FROM Categorias
    ORDER BY Nombre;
END$$

-- CREATE: el codigo se genera automaticamente segun la categoria
CREATE PROCEDURE sp_create_producto(
    IN p_Nombre       VARCHAR(100),
    IN p_Descripcion  VARCHAR(250),
    IN p_CategoriaId  INT,
    IN p_Precio       DECIMAL(10,2),
    IN p_Stock        INT,
    IN p_FechaIngreso DATE)
BEGIN
    DECLARE v_codigo VARCHAR(20);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
        CALL sp_generar_codigo(p_CategoriaId, v_codigo);

        INSERT INTO Productos (Codigo, Nombre, Descripcion, CategoriaId, Precio, Stock, FechaIngreso)
        VALUES (v_codigo, p_Nombre, p_Descripcion, p_CategoriaId, p_Precio, p_Stock, p_FechaIngreso);

        SELECT LAST_INSERT_ID() AS ProductoId, v_codigo AS Codigo;
    COMMIT;
END$$

-- READ: productos con busqueda opcional por codigo, nombre o categoria
CREATE PROCEDURE sp_read_productos(IN p_Buscar VARCHAR(100))
BEGIN
    SELECT p.ProductoId, p.Codigo, p.Nombre, p.Descripcion,
           p.CategoriaId, c.Nombre AS Categoria,
           p.Precio, p.Stock, p.FechaIngreso,
           CAST(p.Precio * p.Stock AS DECIMAL(12,2)) AS ValorTotal
    FROM Productos p
    INNER JOIN Categorias c ON c.CategoriaId = p.CategoriaId
    WHERE p_Buscar IS NULL OR p_Buscar = ''
       OR p.Codigo LIKE CONCAT('%', p_Buscar, '%')
       OR p.Nombre LIKE CONCAT('%', p_Buscar, '%')
       OR c.Nombre LIKE CONCAT('%', p_Buscar, '%')
    ORDER BY p.Codigo;
END$$

-- READ: un producto por Id
CREATE PROCEDURE sp_read_producto_id(IN p_ProductoId INT)
BEGIN
    SELECT ProductoId, Codigo, Nombre, Descripcion, CategoriaId, Precio, Stock, FechaIngreso
    FROM Productos
    WHERE ProductoId = p_ProductoId;
END$$

-- READ: resumen para la pagina de inicio
CREATE PROCEDURE sp_resumen_inventario()
BEGIN
    SELECT COUNT(*)                                   AS TotalProductos,
           IFNULL(SUM(Stock), 0)                      AS TotalUnidades,
           IFNULL(SUM(Precio * Stock), 0)             AS ValorInventario,
           (SELECT COUNT(*) FROM Categorias)          AS TotalCategorias
    FROM Productos;
END$$

-- UPDATE: si cambia la categoria, el producto recibe un codigo nuevo de esa categoria
CREATE PROCEDURE sp_update_producto(
    IN p_ProductoId   INT,
    IN p_Nombre       VARCHAR(100),
    IN p_Descripcion  VARCHAR(250),
    IN p_CategoriaId  INT,
    IN p_Precio       DECIMAL(10,2),
    IN p_Stock        INT,
    IN p_FechaIngreso DATE)
BEGIN
    DECLARE v_categoriaActual INT DEFAULT NULL;
    DECLARE v_codigo VARCHAR(20) DEFAULT NULL;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
        SELECT CategoriaId, Codigo INTO v_categoriaActual, v_codigo
        FROM Productos
        WHERE ProductoId = p_ProductoId
        FOR UPDATE;

        IF v_categoriaActual IS NULL THEN
            COMMIT;
            SELECT 0 AS FilasAfectadas, NULL AS Codigo;
        ELSE
            IF v_categoriaActual <> p_CategoriaId THEN
                CALL sp_generar_codigo(p_CategoriaId, v_codigo);
            END IF;

            UPDATE Productos
               SET Codigo       = v_codigo,
                   Nombre       = p_Nombre,
                   Descripcion  = p_Descripcion,
                   CategoriaId  = p_CategoriaId,
                   Precio       = p_Precio,
                   Stock        = p_Stock,
                   FechaIngreso = p_FechaIngreso
             WHERE ProductoId = p_ProductoId;

            COMMIT;
            SELECT 1 AS FilasAfectadas, v_codigo AS Codigo;
        END IF;
END$$

-- DELETE
CREATE PROCEDURE sp_delete_producto(IN p_ProductoId INT)
BEGIN
    DELETE FROM Productos WHERE ProductoId = p_ProductoId;

    SELECT ROW_COUNT() AS FilasAfectadas;
END$$

DELIMITER ;

/* Prueba rapida */
CALL sp_read_productos(NULL);
