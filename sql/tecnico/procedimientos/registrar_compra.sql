-- =============================================================
-- Aura Store - Procedimiento para registrar una compra
-- Etapa V - Procedimientos y funciones almacenadas
-- =============================================================
-- Ejecutar despues de auditar_precio_producto.sql y verif_stock.sql,
-- segun el paso 4 del README. Cada llamada registra una compra de
-- un producto y talle y devuelve su id en @id_compra_generada.
-- =============================================================

USE aura_store;
GO

SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE dbo.sp_registrar_compra
    @id_cliente INT,
    @id_metodo  INT,
    @id_producto INT,
    @talle       VARCHAR(5),
    @cantidad    INT,
    @id_compra_generada INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- =========================================================
    -- A. VALIDACIONES PREVIAS
    -- Antes de abrir la transaccion, se valida la cantidad y se busca
    -- la fila de stock y el precio de catalogo para el detalle.
    -- =========================================================
    -- Un rechazo esperado permite que el llamador siga usando su transaccion.
    SET XACT_ABORT OFF;

    IF @cantidad IS NULL OR @cantidad <= 0
        THROW 50002, 'La cantidad comprada debe ser mayor que cero.', 1;

    DECLARE @stock_id INT;
    DECLARE @precio_actual DECIMAL(10,2);

    SELECT
        @stock_id      = s.stock_id,
        @precio_actual = p.precio_actual
    FROM stock s
    JOIN producto p ON p.id_producto = s.id_producto
    WHERE s.id_producto = @id_producto
      AND s.talle       = @talle;

    IF @stock_id IS NULL
    BEGIN
        RAISERROR('No existe stock cargado para ese producto y talle.', 16, 1);
        RETURN;
    END

    -- La funcion comprueba si el talle tiene la cantidad pedida.
    IF dbo.fn_verificar_disponibilidad_stock(@id_producto, @talle, @cantidad) = 0
    BEGIN
        RAISERROR('Stock insuficiente para completar la compra.', 16, 1);
        RETURN;
    END

    -- =========================================================
    -- B. REGISTRO DE LA COMPRA
    -- El descuento de stock y las inserciones de compra y detalle
    -- se hacen en la misma transaccion.
    -- =========================================================
    -- Un error de escritura, como una clave foranea invalida, requiere rollback.
    SET XACT_ABORT ON;
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Se verifica el stock al descontarlo por si otra compra
        -- consumio unidades desde la consulta inicial.
        UPDATE dbo.stock
        SET cantidad_disponible = cantidad_disponible - @cantidad
        WHERE stock_id = @stock_id
          AND cantidad_disponible >= @cantidad;

        IF @@ROWCOUNT = 0
            THROW 50001, 'Stock insuficiente para completar la compra.', 1;

        INSERT INTO compra (id_cliente, id_metodo, fecha)
        VALUES (@id_cliente, @id_metodo, GETDATE());

        -- Se usa el id del encabezado recien insertado para el detalle.
        SET @id_compra_generada = SCOPE_IDENTITY();

        INSERT INTO detalle_compra (id_compra, stock_id, cantidad_comprada, precio_unitario)
        VALUES (@id_compra_generada, @stock_id, @cantidad, @precio_actual);

        -- Si el llamador abrio una transaccion, su nivel sigue abierto.
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Se revierte la transaccion abierta y se vuelve a lanzar el error.
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END;
