-- =============================================================
-- Aura Store - Auditoria de cambios de precio
-- Etapa V - Triggers de auditoria
-- =============================================================
-- Ejecutar despues de crear la base, como parte del paso 4 del
-- README. La auditoria se guarda en la transaccion del UPDATE
-- que cambia los precios.
-- =============================================================

USE aura_store;
GO

-- =========================================================
-- A. TABLA DE AUDITORIA
-- El id del producto se guarda sin clave foranea para conservar
-- su historial aunque se elimine del catalogo.
-- =========================================================
IF OBJECT_ID(N'dbo.auditoria_precio_producto', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.auditoria_precio_producto (
        id_auditoria BIGINT IDENTITY(1,1) NOT NULL,
        id_producto INT NOT NULL,
        precio_anterior DECIMAL(10,2) NOT NULL,
        precio_nuevo DECIMAL(10,2) NOT NULL,
        fecha_cambio_utc DATETIME2(3) NOT NULL,
        login_cambio SYSNAME NOT NULL,
        CONSTRAINT PK_auditoria_precio_producto PRIMARY KEY (id_auditoria)
    );
END;
GO

-- =========================================================
-- B. REGISTRO DE CAMBIOS DE PRECIO
-- Se registra una fila por cada producto cuyo precio cambia,
-- incluso si el UPDATE afecta varios productos. Se guardan ambos
-- precios, la fecha y hora en UTC y el login original de la sesion.
-- =========================================================
CREATE OR ALTER TRIGGER dbo.trg_auditar_precio_producto
ON dbo.producto
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Si el UPDATE incluye precio_actual, se comparan los valores
    -- nuevos de inserted con los anteriores de deleted por producto.
    IF NOT UPDATE(precio_actual)
        RETURN;

    INSERT INTO dbo.auditoria_precio_producto (
        id_producto, precio_anterior, precio_nuevo, fecha_cambio_utc, login_cambio
    )
    SELECT i.id_producto, d.precio_actual, i.precio_actual, SYSUTCDATETIME(), ORIGINAL_LOGIN()
    FROM inserted AS i
    INNER JOIN deleted AS d ON d.id_producto = i.id_producto
    WHERE i.precio_actual <> d.precio_actual;
END;
GO

-- =========================================================
-- C. RETIRO DEL TRIGGER DE STOCK ANTERIOR
-- El procedimiento de compra se encarga de descontar el stock.
-- Completar el paso 4 del README antes de registrar nuevas compras.
-- =========================================================
IF OBJECT_ID(N'dbo.auditoria_precio_producto', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.trg_auditar_precio_producto', N'TR') IS NOT NULL
    DROP TRIGGER IF EXISTS dbo.trg_actualizar_stock_despues_de_compra;
GO
