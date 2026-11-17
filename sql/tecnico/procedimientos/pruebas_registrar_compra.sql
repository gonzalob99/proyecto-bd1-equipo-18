-- =============================================================
-- Aura Store - Procedimiento de compra y funcion de stock
-- Etapa V - Procedimientos y funciones almacenadas
-- =============================================================
-- Ejecutar TODO el archivo en una misma conexion de SQL Server,
-- sobre la base de prueba y con los pasos 2 a 4 del README hechos.
-- Revisar las pestanas Resultados y Mensajes en SSMS.
-- La compra de ejemplo se revierte. El IDENTITY puede dejar saltos.
-- =============================================================

USE aura_store;
GO

SET NOCOUNT ON;
SET IMPLICIT_TRANSACTIONS OFF;

IF @@TRANCOUNT <> 0
    THROW 51000, 'Ejecutar la prueba sin una transaccion abierta.', 1;

IF OBJECT_ID(N'dbo.sp_registrar_compra', N'P') IS NULL
   OR OBJECT_ID(N'dbo.fn_verificar_disponibilidad_stock', N'FN') IS NULL
    THROW 51001, 'Instalar la funcion de stock y el procedimiento de compra.', 1;

-- Del DML se toman el cliente 2, Mercado Pago y la camiseta de
-- Boca talle M. Se usa el stock actual para calcular el limite.
DECLARE @id_cliente INT = 2, @id_metodo INT = 4;
DECLARE @id_producto INT = 1, @talle VARCHAR(5) = 'M';
DECLARE @stock_id INT, @stock_inicial INT, @precio DECIMAL(10,2);
DECLARE @compra_generada INT, @compra_rechazada INT, @error_esperado INT;
DECLARE @casos_funcion TABLE (
    caso VARCHAR(40),
    esperado BIT,
    obtenido BIT
);

BEGIN TRY
    BEGIN TRANSACTION;

    SELECT @stock_id = s.stock_id,
           @stock_inicial = s.cantidad_disponible,
           @precio = p.precio_actual
    FROM dbo.stock AS s WITH (UPDLOCK, HOLDLOCK)
    JOIN dbo.producto AS p ON p.id_producto = s.id_producto
    WHERE s.id_producto = @id_producto AND s.talle = @talle;

    IF @stock_inicial IS NULL OR @stock_inicial <= 0
       OR NOT EXISTS (SELECT 1 FROM dbo.cliente WHERE id_cliente = @id_cliente)
       OR NOT EXISTS (SELECT 1 FROM dbo.metodo_pago WHERE id_metodo = @id_metodo)
        THROW 51002, 'Se requieren los datos de ejemplo y stock positivo para el producto 1, talle M.', 1;

    DECLARE @cantidad_excedida INT = @stock_inicial + 1;

    -- =========================================================
    -- A. FUNCION DE DISPONIBILIDAD
    -- Pedir exactamente el stock devuelve 1. Pedir una unidad mas
    -- o un talle que no figura en el DML devuelve 0.
    -- =========================================================
    PRINT 'A. Funcion de disponibilidad';

    INSERT INTO @casos_funcion (caso, esperado, obtenido)
    VALUES
        ('Cantidad igual al stock', 1,
         dbo.fn_verificar_disponibilidad_stock(@id_producto, @talle, @stock_inicial)),
        ('Una unidad por encima del stock', 0,
         dbo.fn_verificar_disponibilidad_stock(@id_producto, @talle, @cantidad_excedida)),
        ('Talle sin stock cargado', 0,
         dbo.fn_verificar_disponibilidad_stock(@id_producto, 'XXXL', 1));

    SELECT caso, esperado, obtenido FROM @casos_funcion;

    IF EXISTS (SELECT 1 FROM @casos_funcion WHERE obtenido <> esperado OR obtenido IS NULL)
        THROW 51003, 'La funcion devolvio una disponibilidad distinta de la esperada.', 1;

    -- =========================================================
    -- B. COMPRA RECHAZADA
    -- La validacion devuelve el error de stock insuficiente,
    -- deja el parametro OUTPUT en NULL y conserva el stock.
    -- =========================================================
    PRINT 'B. Compra rechazada por falta de stock';

    BEGIN TRY
        EXEC dbo.sp_registrar_compra
            @id_cliente = @id_cliente, @id_metodo = @id_metodo,
            @id_producto = @id_producto, @talle = @talle,
            @cantidad = @cantidad_excedida,
            @id_compra_generada = @compra_rechazada OUTPUT;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 50000 OR ERROR_MESSAGE() <> N'Stock insuficiente para completar la compra.'
            THROW;

        SET @error_esperado = ERROR_NUMBER();
        SELECT @error_esperado AS numero_error, ERROR_MESSAGE() AS mensaje_esperado;
    END CATCH;

    IF @error_esperado IS NULL OR @compra_rechazada IS NOT NULL
       OR NOT EXISTS (
           SELECT 1 FROM dbo.stock
           WHERE stock_id = @stock_id AND cantidad_disponible = @stock_inicial
       )
        THROW 51004, 'La compra excedida debia rechazarse sin descontar stock.', 1;

    -- =========================================================
    -- C. COMPRA VALIDA
    -- El OUTPUT identifica una compra con un detalle. Se guarda
    -- el precio vigente y se descuenta exactamente una unidad.
    -- =========================================================
    PRINT 'C. Compra valida de una unidad';

    EXEC dbo.sp_registrar_compra
        @id_cliente = @id_cliente, @id_metodo = @id_metodo,
        @id_producto = @id_producto, @talle = @talle, @cantidad = 1,
        @id_compra_generada = @compra_generada OUTPUT;

    SELECT c.id_compra AS id_compra_generada, c.id_cliente, c.id_metodo,
           d.stock_id, d.cantidad_comprada, d.precio_unitario,
           @stock_inicial AS stock_antes, s.cantidad_disponible AS stock_despues
    FROM dbo.compra AS c
    JOIN dbo.detalle_compra AS d ON d.id_compra = c.id_compra
    JOIN dbo.stock AS s ON s.stock_id = d.stock_id
    WHERE c.id_compra = @compra_generada;

    IF (SELECT COUNT(*) FROM dbo.detalle_compra WHERE id_compra = @compra_generada) <> 1
       OR NOT EXISTS (
           SELECT 1
           FROM dbo.compra AS c
           JOIN dbo.detalle_compra AS d ON d.id_compra = c.id_compra
           JOIN dbo.stock AS s ON s.stock_id = d.stock_id
           WHERE c.id_compra = @compra_generada
             AND c.id_cliente = @id_cliente AND c.id_metodo = @id_metodo
             AND d.stock_id = @stock_id AND d.cantidad_comprada = 1
             AND d.precio_unitario = @precio
             AND s.cantidad_disponible = @stock_inicial - 1
       )
        THROW 51005, 'La compra, su detalle o el descuento de stock son incorrectos.', 1;

    -- El COMMIT del procedimiento cierra su nivel. La transaccion
    -- externa de la prueba permite deshacer la compra de ejemplo.
    IF @@TRANCOUNT <> 1
        THROW 51006, 'El procedimiento debia cerrar su nivel de transaccion.', 1;

    ROLLBACK TRANSACTION;
    PRINT 'Prueba correcta. Se revirtio la compra de ejemplo.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
