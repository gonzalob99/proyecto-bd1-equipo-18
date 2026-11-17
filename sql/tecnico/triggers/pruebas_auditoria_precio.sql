-- =============================================================
-- Aura Store - Auditoria de cambios de precio
-- Etapa V - Triggers de auditoria
-- =============================================================
-- Ejecutar TODO el archivo en una misma conexion de SQL Server,
-- sobre la base de prueba y con los pasos 2 a 4 del README hechos.
-- Se revierten los cambios de productos y los registros de
-- auditoria. El IDENTITY de auditoria puede dejar saltos.
-- =============================================================

USE aura_store;
GO

SET NOCOUNT ON;
SET IMPLICIT_TRANSACTIONS OFF;

IF @@TRANCOUNT <> 0
    THROW 51000, 'Ejecutar la prueba sin una transaccion abierta.', 1;

IF OBJECT_ID(N'dbo.auditoria_precio_producto', N'U') IS NULL
   OR OBJECT_ID(N'dbo.trg_auditar_precio_producto', N'TR') IS NULL
    THROW 51001, 'Instalar la auditoria con auditar_precio_producto.sql.', 1;

DECLARE @productos_antes TABLE (
    id_producto INT PRIMARY KEY,
    precio_actual DECIMAL(10,2),
    descripcion VARCHAR(255)
);

DECLARE @auditoria_prueba TABLE (
    id_auditoria BIGINT PRIMARY KEY,
    id_producto INT,
    precio_anterior DECIMAL(10,2),
    precio_nuevo DECIMAL(10,2),
    fecha_cambio_utc DATETIME2(3),
    login_cambio SYSNAME
);

DECLARE @ultima_auditoria BIGINT;
DECLARE @inicio_utc DATETIME2(3), @fin_utc DATETIME2(3);

BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO @productos_antes (id_producto, precio_actual, descripcion)
    SELECT id_producto, precio_actual, descripcion
    FROM dbo.producto WITH (UPDLOCK, HOLDLOCK)
    WHERE id_producto IN (1, 2, 3);

    IF (SELECT COUNT(*) FROM @productos_antes) <> 3
        THROW 51002, 'Se requieren los productos 1, 2 y 3 de datos_prueba.sql.', 1;

    SELECT @ultima_auditoria = ISNULL(MAX(id_auditoria), 0)
    FROM dbo.auditoria_precio_producto;

    -- =========================================================
    -- A. UPDATE DE VARIOS PRODUCTOS
    -- Un solo UPDATE aumenta $1000 a los productos 1 y 2 y
    -- conserva el precio del producto 3. Se esperan dos registros.
    -- =========================================================
    PRINT 'A. Cambian dos precios en una misma sentencia';
    SET @inicio_utc = SYSUTCDATETIME();

    UPDATE dbo.producto
    SET precio_actual = CASE WHEN id_producto IN (1, 2)
                             THEN precio_actual + 1000.00
                             ELSE precio_actual END
    WHERE id_producto IN (1, 2, 3);

    -- =========================================================
    -- B. UPDATE DE OTRA COLUMNA
    -- Cambiar solo la descripcion deja el total en dos registros.
    -- Se muestran los valores guardados por el trigger.
    -- =========================================================
    PRINT 'B. Cambia una descripcion y se revisa la auditoria';

    UPDATE dbo.producto
    SET descripcion = CASE WHEN descripcion IS NULL THEN 'Descripcion temporal' ELSE NULL END
    WHERE id_producto = 1;

    SET @fin_utc = SYSUTCDATETIME();

    -- La variable de tabla conserva los identificadores para
    -- verificar despues del rollback que se eliminaron esas filas.
    INSERT INTO @auditoria_prueba
    SELECT id_auditoria, id_producto, precio_anterior, precio_nuevo, fecha_cambio_utc, login_cambio
    FROM dbo.auditoria_precio_producto
    WHERE id_auditoria > @ultima_auditoria
      AND id_producto IN (1, 2, 3);

    SELECT id_producto, precio_anterior, precio_nuevo, fecha_cambio_utc, login_cambio
    FROM @auditoria_prueba
    ORDER BY id_producto;

    IF (SELECT COUNT(*) FROM @auditoria_prueba) <> 2
       OR EXISTS (
           SELECT id_producto, precio_actual, precio_actual + 1000.00
           FROM @productos_antes WHERE id_producto IN (1, 2)
           EXCEPT
           SELECT id_producto, precio_anterior, precio_nuevo
           FROM @auditoria_prueba
       )
       OR EXISTS (
           SELECT 1 FROM @auditoria_prueba
           WHERE fecha_cambio_utc NOT BETWEEN @inicio_utc AND @fin_utc
              OR login_cambio <> ORIGINAL_LOGIN()
       )
        THROW 51003, 'Se esperaban dos registros con los precios, la fecha UTC y el login correctos.', 1;

    -- =========================================================
    -- C. ROLLBACK
    -- Los productos recuperan sus valores iniciales y ninguna
    -- fila de auditoria de esta prueba queda persistida.
    -- =========================================================
    PRINT 'C. Se revierten los cambios y su auditoria';
    ROLLBACK TRANSACTION;

    DECLARE @filas_persistidas INT;

    SELECT @filas_persistidas = COUNT(*)
    FROM dbo.auditoria_precio_producto AS a
    JOIN @auditoria_prueba AS p ON p.id_auditoria = a.id_auditoria;

    SELECT @filas_persistidas AS registros_de_la_prueba_persistidos;

    IF @filas_persistidas <> 0
       OR EXISTS (
           SELECT id_producto, precio_actual, descripcion FROM @productos_antes
           EXCEPT
           SELECT id_producto, precio_actual, descripcion FROM dbo.producto
       )
        THROW 51004, 'El rollback debia restaurar los productos y retirar las filas de auditoria.', 1;

    PRINT 'Prueba correcta.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
