USE aura_store;
GO

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

CREATE OR ALTER TRIGGER dbo.trg_auditar_precio_producto
ON dbo.producto
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

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

-- Retirar el trigger anterior una vez instalada la auditoria.
IF OBJECT_ID(N'dbo.auditoria_precio_producto', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.trg_auditar_precio_producto', N'TR') IS NOT NULL
    DROP TRIGGER IF EXISTS dbo.trg_actualizar_stock_despues_de_compra;
GO
